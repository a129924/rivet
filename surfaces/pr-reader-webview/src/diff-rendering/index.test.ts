import type {
  DiffFacade,
  DiffFileStatus,
  DiffRenderOutcome,
  DiffSnapshot,
  DiffViewModel,
  ViewedStateChange,
} from "./index";

type Equal<Left, Right> =
  (<Value>() => Value extends Left ? 1 : 2) extends <
    Value,
  >() => Value extends Right ? 1 : 2
    ? true
    : false;

type Expect<Condition extends true> = Condition;

type _facade = Expect<DiffFacade extends object ? true : false>;
type _status = Expect<
  Equal<DiffFileStatus, "added" | "removed" | "modified" | "renamed">
>;
type _outcome = Expect<DiffRenderOutcome extends object ? true : false>;
type _viewModel = Expect<DiffViewModel extends object ? true : false>;
type _snapshot = Expect<DiffSnapshot extends object ? true : false>;
type _viewedStateChange = Expect<
  ViewedStateChange extends object ? true : false
>;

// @ts-expect-error Internal ports are not part of the public barrel.
type _internalPortIsNotPublic = import("./index").DiffParserPort;

// @ts-expect-error Internal opaque stage types are not part of the public barrel.
type _opaqueStageTypeIsNotPublic = import("./index").ValidatedDiffInput;

// @ts-expect-error Internal use cases are not part of the public barrel.
type _useCaseIsNotPublic = import("./index").DiffRenderUseCase;

// @ts-expect-error Internal use case factories are not part of the public barrel.
type _useCaseFactoryIsNotPublic = import("./index").createDiffRenderUseCase;

// @ts-expect-error Internal facade factories are not part of the public barrel.
type _facadeFactoryIsNotPublic = import("./index").createDiffFacade;

// @ts-expect-error Adapter boundaries are not part of the public barrel.
type _adapterIsNotPublic = import("./index").DiffSnapshotAdapter;
