import { TagRecord } from "../../common.gen.js";

export type GenericID<T> = string & TagRecord<"GenericID", [T]>;

export type GenericID2<_IDSpecifier, RawValue> = RawValue & TagRecord<"GenericID2", [_IDSpecifier, RawValue]>;

export type GenericID2_JSON<_IDSpecifier_JSON, RawValue_JSON> = RawValue_JSON;

export function GenericID2_decode<
    _IDSpecifier,
    _IDSpecifier_JSON,
    RawValue,
    RawValue_JSON
>(json: GenericID2_JSON<_IDSpecifier_JSON, RawValue_JSON>, _IDSpecifier_decode: (json: _IDSpecifier_JSON) => _IDSpecifier, RawValue_decode: (json: RawValue_JSON) => RawValue): GenericID2<_IDSpecifier, RawValue> {
    return RawValue_decode(json) as GenericID2<_IDSpecifier, RawValue>;
}

export function GenericID2_encode<
    _IDSpecifier,
    _IDSpecifier_JSON,
    RawValue,
    RawValue_JSON
>(entity: GenericID2<_IDSpecifier, RawValue>, _IDSpecifier_encode: (entity: _IDSpecifier) => _IDSpecifier_JSON, RawValue_encode: (entity: RawValue) => RawValue_JSON): GenericID2_JSON<_IDSpecifier_JSON, RawValue_JSON> {
    return RawValue_encode(entity);
}

export type MyValue = ({
    kind: "id";
    id: {
        _0: string;
    };
} | {
    kind: "none";
    none: {};
}) & TagRecord<"MyValue">;

export type MyValue_JSON = {
    id: {
        _0: string;
    };
} | {
    none: {};
};

export function MyValue_decode(json: MyValue_JSON): MyValue {
    if ("id" in json) {
        const j = json.id;
        const _0 = j._0;
        return {
            kind: "id",
            id: {
                _0: _0
            }
        };
    } else if ("none" in json) {
        return {
            kind: "none",
            none: {}
        };
    } else {
        throw new Error("unknown kind");
    }
}

export type GenericID3<T> = MyValue & TagRecord<"GenericID3", [T]>;

export type GenericID3_JSON<T_JSON> = MyValue_JSON;

export function GenericID3_decode<T, T_JSON>(json: GenericID3_JSON<T_JSON>, T_decode: (json: T_JSON) => T): GenericID3<T> {
    return MyValue_decode(json) as GenericID3<T>;
}
