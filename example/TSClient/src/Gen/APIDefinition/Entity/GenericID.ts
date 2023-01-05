import { TagRecord } from "../../common.js";

export type GenericIDz<T> = {
    rawValue: string;
} & TagRecord<"GenericIDz", [T]>;

export type GenericIDz_JSON<T_JSON> = string;

export function GenericIDz_decode<T, T_JSON>(json: GenericIDz_JSON<T_JSON>, T_decode: (json: T_JSON) => T): GenericIDz<T> {
    return {
        rawValue: json
    };
}

export function GenericIDz_encode<T, T_JSON>(entity: GenericIDz<T>, T_encode: (entity: T) => T_JSON): GenericIDz_JSON<T_JSON> {
    return entity.rawValue;
}
