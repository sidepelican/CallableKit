import { TagRecord } from "../common.gen.js";

export type CodableResult<T, E> = ({
    kind: "success";
    success: {
        _0: T;
    };
} | {
    kind: "failure";
    failure: {
        _0: E;
    };
}) & TagRecord<"CodableResult", [T, E]>;

export type CodableResult$JSON<T$JSON, E$JSON> = {
    success: {
        _0: T$JSON;
    };
} | {
    failure: {
        _0: E$JSON;
    };
};

export function CodableResult_decode<
    T,
    T$JSON,
    E,
    E$JSON
>(json: CodableResult$JSON<T$JSON, E$JSON>, T_decode: (json: T$JSON) => T, E_decode: (json: E$JSON) => E): CodableResult<T, E> {
    if ("success" in json) {
        const j = json.success;
        const _0 = T_decode(j._0);
        return {
            kind: "success",
            success: {
                _0: _0
            }
        };
    } else if ("failure" in json) {
        const j = json.failure;
        const _0 = E_decode(j._0);
        return {
            kind: "failure",
            failure: {
                _0: _0
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}

export function CodableResult_encode<
    T,
    T$JSON,
    E,
    E$JSON
>(entity: CodableResult<T, E>, T_encode: (entity: T) => T$JSON, E_encode: (entity: E) => E$JSON): CodableResult$JSON<T$JSON, E$JSON> {
    switch (entity.kind) {
    case "success":
        {
            const e = entity.success;
            const _0 = T_encode(e._0);
            return {
                success: {
                    _0: _0
                }
            };
        }
    case "failure":
        {
            const e = entity.failure;
            const _0 = E_encode(e._0);
            return {
                failure: {
                    _0: _0
                }
            };
        }
    default:
        const check: never = entity;
        throw new Error("invalid case: " + check);
    }
}
