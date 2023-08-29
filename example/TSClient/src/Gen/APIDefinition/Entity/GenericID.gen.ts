import { TagRecord } from "../../common.gen.js";

export type GenericID<T> = string & TagRecord<"GenericID", [T]>;

export type GenericID2<_IDSpecifier, RawValue> = RawValue & TagRecord<"GenericID2", [_IDSpecifier, RawValue]>;
