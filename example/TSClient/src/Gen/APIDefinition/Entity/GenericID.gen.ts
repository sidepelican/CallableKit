import { TagRecord } from "../../common.gen.js";

export type GenericID<T> = string & TagRecord<"GenericID", [T]>;
