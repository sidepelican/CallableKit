import { TagRecord } from "../../common.gen.js";

export type GenericID<T> = string & TagRecord<"GenericID", [T]>;

export type GenericID2<_IDSpecifier, RawValue> = RawValue & TagRecord<"GenericID2", [_IDSpecifier, RawValue]>;

export type GenericID2$JSON<_IDSpecifier$JSON, RawValue$JSON> = {
    rawValue: RawValue$JSON;
};

export function GenericID2_decode<
    _IDSpecifier,
    _IDSpecifier$JSON,
    RawValue,
    RawValue$JSON
>(json: GenericID2$JSON<_IDSpecifier$JSON, RawValue$JSON>, _IDSpecifier_decode: (json: _IDSpecifier$JSON) => _IDSpecifier, RawValue_decode: (json: RawValue$JSON) => RawValue): GenericID2<_IDSpecifier, RawValue> {
    return RawValue_decode(json.rawValue) as GenericID2<_IDSpecifier, RawValue>;
}

export function GenericID2_encode<
    _IDSpecifier,
    _IDSpecifier$JSON,
    RawValue,
    RawValue$JSON
>(entity: GenericID2<_IDSpecifier, RawValue>, _IDSpecifier_encode: (entity: _IDSpecifier) => _IDSpecifier$JSON, RawValue_encode: (entity: RawValue) => RawValue$JSON): GenericID2$JSON<_IDSpecifier$JSON, RawValue$JSON> {
    return {
        rawValue: RawValue_encode(entity)
    };
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

export type MyValue$JSON = {
    id: {
        _0: string;
    };
} | {
    none: {};
};

export function MyValue_decode(json: MyValue$JSON): MyValue {
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

export type GenericID3$JSON<T$JSON> = {
    rawValue: MyValue$JSON;
};

export function GenericID3_decode<T, T$JSON>(json: GenericID3$JSON<T$JSON>, T_decode: (json: T$JSON) => T): GenericID3<T> {
    return MyValue_decode(json.rawValue) as GenericID3<T>;
}

export function GenericID3_encode<T, T$JSON>(entity: GenericID3<T>, T_encode: (entity: T) => T$JSON): GenericID3$JSON<T$JSON> {
    return {
        rawValue: entity as MyValue$JSON
    };
}

export type GenericID3_RawValue<T> = MyValue;

export type GenericID3_RawValue$JSON<T$JSON> = MyValue$JSON;

export function GenericID3_RawValue_decode<T, T$JSON>(json: GenericID3_RawValue$JSON<T$JSON>, T_decode: (json: T$JSON) => T): GenericID3_RawValue<T> {
    return MyValue_decode(json);
}

export type GenericID4<_IDSpecifier, RawValue> = RawValue & TagRecord<"GenericID4", [_IDSpecifier, RawValue]>;
