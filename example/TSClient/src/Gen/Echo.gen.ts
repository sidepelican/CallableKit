import { Student, Student_JSON, Student_decode } from "./Student.gen.js";
import { User, User_JSON, User_decode } from "./User.gen.js";
import { IStubClient } from "./common.gen.js";
import {
    Array_decode,
    Date_decode,
    Date_encode,
    OptionalField_decode,
    Optional_decode,
    identity
} from "./decode.gen.js";

export interface IEchoClient {
    hello(request: EchoHelloRequest): Promise<EchoHelloResponse>;
    tommorow(now: Date): Promise<Date>;
    testTypicalEntity(request: User): Promise<User>;
    testComplexType(request: TestComplexType_Request): Promise<TestComplexType_Response>;
    emptyRequestAndResponse(): Promise<void>;
    testTypeAliasToRawRepr(request: Student): Promise<Student>;
}

export const bindEcho = (stub: IStubClient): IEchoClient => {
    return {
        async hello(request: EchoHelloRequest): Promise<EchoHelloResponse> {
            return await stub.send(request, "Echo/hello") as EchoHelloResponse;
        },
        async tommorow(now: Date): Promise<Date> {
            const json = await stub.send(Date_encode(now), "Echo/tommorow") as number;
            return Date_decode(json);
        },
        async testTypicalEntity(request: User): Promise<User> {
            const json = await stub.send(request, "Echo/testTypicalEntity") as User_JSON;
            return User_decode(json);
        },
        async testComplexType(request: TestComplexType_Request): Promise<TestComplexType_Response> {
            const json = await stub.send(request, "Echo/testComplexType") as TestComplexType_Response_JSON;
            return TestComplexType_Response_decode(json);
        },
        async emptyRequestAndResponse(): Promise<void> {
            return await stub.send({}, "Echo/emptyRequestAndResponse") as void;
        },
        async testTypeAliasToRawRepr(request: Student): Promise<Student> {
            const json = await stub.send(request, "Echo/testTypeAliasToRawRepr") as Student_JSON;
            return Student_decode(json);
        }
    };
};

export type EchoHelloRequest = {
    name: string;
};

export type EchoHelloResponse = {
    message: string;
};

export type TestComplexType = never;

export type TestComplexType_K<T> = {
    x: T;
};

export type TestComplexType_K_JSON<T_JSON> = {
    x: T_JSON;
};

export function TestComplexType_K_decode<T, T_JSON>(json: TestComplexType_K_JSON<T_JSON>, T_decode: (json: T_JSON) => T): TestComplexType_K<T> {
    return {
        x: T_decode(json.x)
    };
}

export function TestComplexType_K_encode<T, T_JSON>(entity: TestComplexType_K<T>, T_encode: (entity: T) => T_JSON): TestComplexType_K_JSON<T_JSON> {
    return {
        x: T_encode(entity.x)
    };
}

export type TestComplexType_E<T> = {
    kind: "k";
    k: {
        _0: TestComplexType_K<T>;
    };
} | {
    kind: "i";
    i: {
        _0: number;
    };
} | {
    kind: "n";
    n: {};
};

export type TestComplexType_E_JSON<T_JSON> = {
    k: {
        _0: TestComplexType_K_JSON<T_JSON>;
    };
} | {
    i: {
        _0: number;
    };
} | {
    n: {};
};

export function TestComplexType_E_decode<T, T_JSON>(json: TestComplexType_E_JSON<T_JSON>, T_decode: (json: T_JSON) => T): TestComplexType_E<T> {
    if ("k" in json) {
        const j = json.k;
        return {
            kind: "k",
            k: {
                _0: TestComplexType_K_decode(j._0, T_decode)
            }
        };
    } else if ("i" in json) {
        const j = json.i;
        return {
            kind: "i",
            i: {
                _0: j._0
            }
        };
    } else if ("n" in json) {
        return {
            kind: "n",
            n: {}
        };
    } else {
        throw new Error("unknown kind");
    }
}

export function TestComplexType_E_encode<T, T_JSON>(entity: TestComplexType_E<T>, T_encode: (entity: T) => T_JSON): TestComplexType_E_JSON<T_JSON> {
    switch (entity.kind) {
    case "k":
        {
            const e = entity.k;
            return {
                k: {
                    _0: TestComplexType_K_encode(e._0, T_encode)
                }
            };
        }
    case "i":
        {
            const e = entity.i;
            return {
                i: {
                    _0: e._0
                }
            };
        }
    case "n":
        {
            return {
                n: {}
            };
        }
    default:
        const check: never = entity;
        throw new Error("invalid case: " + check);
    }
}

export type TestComplexType_L = {
    x: string;
};

export type TestComplexType_Request = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
};

export type TestComplexType_Request_JSON = {
    a?: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Request_decode(json: TestComplexType_Request_JSON): TestComplexType_Request {
    return {
        a: OptionalField_decode(json.a, (json: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
            return TestComplexType_K_decode(json, (json: (TestComplexType_E_JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
                return Array_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                    return Optional_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                        return TestComplexType_E_decode(json, identity);
                    });
                });
            });
        })
    };
}

export type TestComplexType_Response = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
};

export type TestComplexType_Response_JSON = {
    a?: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Response_decode(json: TestComplexType_Response_JSON): TestComplexType_Response {
    return {
        a: OptionalField_decode(json.a, (json: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
            return TestComplexType_K_decode(json, (json: (TestComplexType_E_JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
                return Array_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                    return Optional_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                        return TestComplexType_E_decode(json, identity);
                    });
                });
            });
        })
    };
}
