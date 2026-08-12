#!/usr/bin/env python3

import argparse
from pathlib import Path, PurePosixPath

from xcconfig import assignments, resolve


class Lexer:
    def __init__(self, text):
        self.text = text
        self.offset = 0

    def token(self):
        text = self.text
        length = len(text)
        while self.offset < length:
            if text[self.offset].isspace():
                self.offset += 1
                continue
            if text.startswith("//", self.offset):
                end = text.find("\n", self.offset + 2)
                self.offset = length if end < 0 else end + 1
                continue
            if text.startswith("/*", self.offset):
                end = text.find("*/", self.offset + 2)
                if end < 0:
                    raise ValueError("unterminated comment")
                self.offset = end + 2
                continue
            break

        if self.offset == length:
            return None

        char = text[self.offset]
        if char in "{}()=;,":
            self.offset += 1
            return char
        if char == '"':
            self.offset += 1
            value = []
            while self.offset < length:
                char = text[self.offset]
                self.offset += 1
                if char == '"':
                    return "".join(value)
                if char == "\\":
                    if self.offset == length:
                        break
                    char = text[self.offset]
                    self.offset += 1
                value.append(char)
            raise ValueError("unterminated string")

        start = self.offset
        while self.offset < length:
            if text[self.offset].isspace() or text[self.offset] in "{}()=;,\"":
                break
            if text.startswith("//", self.offset) or text.startswith("/*", self.offset):
                break
            self.offset += 1
        return text[start:self.offset]


class Parser:
    def __init__(self, text):
        self.lexer = Lexer(text)
        self.lookahead = self.lexer.token()

    def take(self, expected=None):
        token = self.lookahead
        if expected is not None and token != expected:
            raise ValueError(f"expected {expected!r}, got {token!r}")
        self.lookahead = self.lexer.token()
        return token

    def value(self):
        if self.lookahead == "{":
            return self.dictionary()
        if self.lookahead == "(":
            return self.array()
        if self.lookahead is None:
            raise ValueError("unexpected end of file")
        return self.take()

    def dictionary(self):
        result = {}
        self.take("{")
        while self.lookahead != "}":
            key = self.take()
            self.take("=")
            result[key] = self.value()
            self.take(";")
        self.take("}")
        return result

    def array(self):
        result = []
        self.take("(")
        while self.lookahead != ")":
            result.append(self.value())
            if self.lookahead == ",":
                self.take(",")
        self.take(")")
        return result


def source_paths(project, target_name, source_root=None, include_flags=False):
    objects = project["objects"]
    targets = [
        value for value in objects.values()
        if value.get("isa") == "PBXNativeTarget" and value.get("name") == target_name
    ]
    if not targets:
        raise ValueError(f"target not found: {target_name}")
    if len(targets) != 1:
        raise ValueError(f"target is ambiguous: {target_name}")
    target = targets[0]

    parents = {}
    for identifier, value in objects.items():
        if value.get("isa") in ("PBXGroup", "PBXVariantGroup"):
            for child in value.get("children", []):
                parents[child] = identifier

    resolved = {}
    def resolve(identifier):
        if identifier in resolved:
            return resolved[identifier]
        value = objects[identifier]
        path = value.get("path", value.get("name", ""))
        source_tree = value.get("sourceTree", "<group>")
        if source_tree == "<group>" and identifier in parents:
            parent = resolve(parents[identifier])
            path = str(PurePosixPath(parent) / path) if path else parent
        elif source_tree not in ("<group>", "SOURCE_ROOT"):
            path = ""
        resolved[identifier] = path
        return path

    paths = []
    for phase_id in target.get("buildPhases", []):
        phase = objects[phase_id]
        if phase.get("isa") != "PBXSourcesBuildPhase":
            continue
        for build_file_id in phase.get("files", []):
            file_id = objects[build_file_id].get("fileRef")
            if file_id:
                path = resolve(file_id)
                if path:
                    if source_root is not None and not (source_root / path).exists():
                        parts = list(PurePosixPath(path).parts)
                        collapsed = [
                            part for index, part in enumerate(parts)
                            if index == 0 or part != parts[index - 1]
                        ]
                        alternative = str(PurePosixPath(*collapsed))
                        if (source_root / alternative).exists():
                            path = alternative
                    if include_flags:
                        flags = objects[build_file_id].get("settings", {}).get(
                            "COMPILER_FLAGS", "")
                        paths.append((path, flags))
                    else:
                        paths.append(path)
    return paths


def main():
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument("project", type=Path)
    argument_parser.add_argument("target")
    argument_parser.add_argument("--flags", action="store_true")
    argument_parser.add_argument("--xcconfig", type=Path)
    argument_parser.add_argument("--variant-xcconfig", type=Path)
    argument_parser.add_argument("--variant")
    arguments = argument_parser.parse_args()

    project = Parser(arguments.project.read_text()).value()
    source_root = arguments.project.parent.parent
    include_flags = (
        arguments.flags or arguments.xcconfig or arguments.variant_xcconfig)
    items = source_paths(project, arguments.target, source_root, include_flags)
    config_path = arguments.variant_xcconfig or arguments.xcconfig
    if config_path:
        values = assignments(config_path)
        values.update({
            "CURRENT_ARCH": "x86_64",
            "PLATFORM_NAME": "macosx",
            "SRCROOT": str(source_root),
        })
    if arguments.variant_xcconfig:
        if not arguments.variant:
            argument_parser.error("--variant is required with --variant-xcconfig")
        values["VARIANT"] = arguments.variant
        included = resolve(
            values["VARIANT_INCLUDED_SOURCE_FILE_NAMES"], values).split()
        selected = [item for item in items if Path(item[0]).name in included]
        if len(selected) != len(included):
            raise ValueError(
                f"variant {arguments.variant} selected {len(selected)} "
                f"of {len(included)} sources")
        items = selected
    for item in items:
        if include_flags:
            path, flags = item
            if config_path:
                flags = resolve(flags, values)
            print(f"{path}\t{flags}")
        else:
            print(item)


if __name__ == "__main__":
    main()
