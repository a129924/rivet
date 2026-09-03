// @ts-expect-error Bun's test module lacks a local type declaration in this package.
import { describe, expect, test } from "bun:test";
import type { DiffRenderOutcome } from "../contracts/diff-view-model";
import type { DiffSnapshot } from "../contracts/diff-snapshot";
import type {
  ParsedDiffInput,
  RenderPlan,
  ValidatedDiffInput,
} from "../contracts/opaque-stage-inputs";
import type { DiffOutputPort } from "../ports/diff-output-port";
import type { DiffParserPort } from "../ports/diff-parser-port";
import type { DiffRendererPort } from "../ports/diff-renderer-port";
import type { DiffViewModelValidatorPort } from "../ports/diff-view-model-validator-port";
import type {
  DiffRenderUseCase,
  DiffRenderUseCaseDependencies,
} from "./diff-render-use-case";
import { createDiffRenderUseCase } from "./diff-render-use-case";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;
type Expect<Condition extends true> = Condition;

type _dependencyKeys = Expect<
  Equal<
    keyof DiffRenderUseCaseDependencies,
    "validator" | "parser" | "renderer" | "output"
  >
>;
type _dependencies = Expect<
  Equal<
    DiffRenderUseCaseDependencies,
    {
      readonly validator: DiffViewModelValidatorPort;
      readonly parser: DiffParserPort;
      readonly renderer: DiffRendererPort;
      readonly output: DiffOutputPort;
    }
  >
>;
type _execute = Expect<
  Equal<
    DiffRenderUseCase["execute"],
    (snapshot: DiffSnapshot) => DiffRenderOutcome
  >
>;

const snapshot: DiffSnapshot = {
  pullRequestId: "pr-123",
  snapshotId: "snapshot-456",
  files: [],
};
const validatedInput = {} as ValidatedDiffInput;
const parsedInput = {} as ParsedDiffInput;
const renderPlan = {} as RenderPlan;

describe("createDiffRenderUseCase", () => {
  test("calls every stage in order and forwards each success value", () => {
    const calls: string[] = [];
    const useCase = createDiffRenderUseCase({
      validator: {
        validate(receivedSnapshot) {
          calls.push("validate");
          expect(receivedSnapshot).toBe(snapshot);
          return { type: "success", value: validatedInput };
        },
      },
      parser: {
        parse(input) {
          calls.push("parse");
          expect(input).toBe(validatedInput);
          return { type: "success", value: parsedInput };
        },
      },
      renderer: {
        createRenderPlan(input) {
          calls.push("render");
          expect(input).toBe(parsedInput);
          return { type: "success", value: renderPlan };
        },
      },
      output: {
        output(input) {
          calls.push("output");
          expect(input).toBe(renderPlan);
          return { type: "success" };
        },
      },
    });

    expect(useCase.execute(snapshot)).toEqual({ type: "success" });
    expect(calls).toEqual(["validate", "parse", "render", "output"]);
  });

  test("returns invalid-input without calling downstream stages", () => {
    const calls: string[] = [];
    const outcome = {
      type: "error",
      kind: "invalid-input",
      message: "invalid snapshot",
    } as const;
    const useCase = createDiffRenderUseCase({
      validator: {
        validate() {
          calls.push("validate");
          return outcome;
        },
      },
      parser: {
        parse() {
          calls.push("parse");
          return { type: "success", value: parsedInput };
        },
      },
      renderer: {
        createRenderPlan() {
          calls.push("render");
          return { type: "success", value: renderPlan };
        },
      },
      output: {
        output() {
          calls.push("output");
          return { type: "success" };
        },
      },
    });

    expect(useCase.execute(snapshot)).toBe(outcome);
    expect(calls).toEqual(["validate"]);
  });

  test("returns parse-error without calling renderer or output", () => {
    const calls: string[] = [];
    const outcome = {
      type: "error",
      kind: "parse-error",
      message: "unparseable diff",
    } as const;
    const useCase = createDiffRenderUseCase({
      validator: {
        validate() {
          calls.push("validate");
          return { type: "success", value: validatedInput };
        },
      },
      parser: {
        parse() {
          calls.push("parse");
          return outcome;
        },
      },
      renderer: {
        createRenderPlan() {
          calls.push("render");
          return { type: "success", value: renderPlan };
        },
      },
      output: {
        output() {
          calls.push("output");
          return { type: "success" };
        },
      },
    });

    expect(useCase.execute(snapshot)).toBe(outcome);
    expect(calls).toEqual(["validate", "parse"]);
  });

  test("returns render-error without calling output", () => {
    const calls: string[] = [];
    const outcome = {
      type: "error",
      kind: "render-error",
      message: "cannot render plan",
    } as const;
    const useCase = createDiffRenderUseCase({
      validator: {
        validate() {
          calls.push("validate");
          return { type: "success", value: validatedInput };
        },
      },
      parser: {
        parse() {
          calls.push("parse");
          return { type: "success", value: parsedInput };
        },
      },
      renderer: {
        createRenderPlan() {
          calls.push("render");
          return outcome;
        },
      },
      output: {
        output() {
          calls.push("output");
          return { type: "success" };
        },
      },
    });

    expect(useCase.execute(snapshot)).toBe(outcome);
    expect(calls).toEqual(["validate", "parse", "render"]);
  });

  test("returns output-error after the first three stages succeed", () => {
    const calls: string[] = [];
    const outcome = {
      type: "error",
      kind: "output-error",
      message: "output failed",
    } as const;
    const useCase = createDiffRenderUseCase({
      validator: {
        validate() {
          calls.push("validate");
          return { type: "success", value: validatedInput };
        },
      },
      parser: {
        parse() {
          calls.push("parse");
          return { type: "success", value: parsedInput };
        },
      },
      renderer: {
        createRenderPlan() {
          calls.push("render");
          return { type: "success", value: renderPlan };
        },
      },
      output: {
        output() {
          calls.push("output");
          return outcome;
        },
      },
    });

    expect(useCase.execute(snapshot)).toBe(outcome);
    expect(calls).toEqual(["validate", "parse", "render", "output"]);
  });
});
