import { Date_decode, Date_encode, IStubClient } from "../CallableKit.gen.js";
import {
    Array_decode,
    OptionalField_decode,
    Optional_decode,
    TagRecord,
    identity
} from "../common.gen.js";
import {
    Student,
    Student2,
    Student2$JSON,
    Student2_decode,
    Student2_encode,
    Student3,
    Student3$JSON,
    Student3_decode,
    Student3_encode,
    Student4,
    Student4$JSON,
    Student4_decode,
    Student4_encode,
    Student5
} from "./Entity/Student.gen.js";
import { User } from "./Entity/User.gen.js";

export interface IEchoClient {
    hello(request: EchoHelloRequest): Promise<EchoHelloResponse>;
    tommorow(now: Date): Promise<Date>;
    testTypicalEntity(request: User): Promise<User>;
    testComplexType(request: TestComplexType_Request): Promise<TestComplexType_Response>;
    emptyRequestAndResponse(): Promise<void>;
    testTypeAliasToRawRepr(request: Student): Promise<Student>;
    testRawRepr(request: Student2): Promise<Student2>;
    testRawRepr2(request: Student3): Promise<Student3>;
    testRawRepr3(request: Student4): Promise<Student4>;
    testRawRepr4(request: Student5): Promise<Student5>;
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
            return await stub.send(request, "Echo/testTypicalEntity") as User;
        },
        async testComplexType(request: TestComplexType_Request): Promise<TestComplexType_Response> {
            const json = await stub.send(request, "Echo/testComplexType") as TestComplexType_Response$JSON;
            return TestComplexType_Response_decode(json);
        },
        async emptyRequestAndResponse(): Promise<void> {
            return await stub.send({}, "Echo/emptyRequestAndResponse") as void;
        },
        async testTypeAliasToRawRepr(request: Student): Promise<Student> {
            return await stub.send(request, "Echo/testTypeAliasToRawRepr") as Student;
        },
        async testRawRepr(request: Student2): Promise<Student2> {
            const json = await stub.send(Student2_encode(request), "Echo/testRawRepr") as Student2$JSON;
            return Student2_decode(json);
        },
        async testRawRepr2(request: Student3): Promise<Student3> {
            const json = await stub.send(Student3_encode(request), "Echo/testRawRepr2") as Student3$JSON;
            return Student3_decode(json);
        },
        async testRawRepr3(request: Student4): Promise<Student4> {
            const json = await stub.send(Student4_encode(request), "Echo/testRawRepr3") as Student4$JSON;
            return Student4_decode(json);
        },
        async testRawRepr4(request: Student5): Promise<Student5> {
            return await stub.send(request, "Echo/testRawRepr4") as Student5;
        }
    };
};

export type EchoHelloRequest = {
    name: string;
} & TagRecord<"EchoHelloRequest">;

export type EchoHelloResponse = {
    message: string;
} & TagRecord<"EchoHelloResponse">;

export type TestComplexType = never;

export type TestComplexType_K<T> = {
    x: T;
} & TagRecord<"TestComplexType_K", [T]>;

export type TestComplexType_K$JSON<T$JSON> = {
    x: T$JSON;
};

export function TestComplexType_K_decode<T, T$JSON>(json: TestComplexType_K$JSON<T$JSON>, T_decode: (json: T$JSON) => T): TestComplexType_K<T> {
    const x = T_decode(json.x);
    return {
        x: x
    };
}

export function TestComplexType_K_encode<T, T$JSON>(entity: TestComplexType_K<T>, T_encode: (entity: T) => T$JSON): TestComplexType_K$JSON<T$JSON> {
    const x = T_encode(entity.x);
    return {
        x: x
    };
}

export type TestComplexType_E<T> = ({
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
}) & TagRecord<"TestComplexType_E", [T]>;

export type TestComplexType_E$JSON<T$JSON> = {
    k: {
        _0: TestComplexType_K$JSON<T$JSON>;
    };
} | {
    i: {
        _0: number;
    };
} | {
    n: {};
};

export function TestComplexType_E_decode<T, T$JSON>(json: TestComplexType_E$JSON<T$JSON>, T_decode: (json: T$JSON) => T): TestComplexType_E<T> {
    if ("k" in json) {
        const j = json.k;
        const _0 = TestComplexType_K_decode<T, T$JSON>(j._0, T_decode);
        return {
            kind: "k",
            k: {
                _0: _0
            }
        };
    } else if ("i" in json) {
        const j = json.i;
        const _0 = j._0;
        return {
            kind: "i",
            i: {
                _0: _0
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

export function TestComplexType_E_encode<T, T$JSON>(entity: TestComplexType_E<T>, T_encode: (entity: T) => T$JSON): TestComplexType_E$JSON<T$JSON> {
    switch (entity.kind) {
    case "k":
        {
            const e = entity.k;
            const _0 = TestComplexType_K_encode<T, T$JSON>(e._0, T_encode);
            return {
                k: {
                    _0: _0
                }
            };
        }
    case "i":
        {
            const e = entity.i;
            const _0 = e._0;
            return {
                i: {
                    _0: _0
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
} & TagRecord<"TestComplexType_L">;

export type TestComplexType_Request = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
} & TagRecord<"TestComplexType_Request">;

export type TestComplexType_Request$JSON = {
    a?: TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Request_decode(json: TestComplexType_Request$JSON): TestComplexType_Request {
    const a = OptionalField_decode<TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>, TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>>(json.a, (json: TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
        return TestComplexType_K_decode<(TestComplexType_E<TestComplexType_L> | null)[], (TestComplexType_E$JSON<TestComplexType_L> | null)[]>(json, (json: (TestComplexType_E$JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
            return Array_decode<TestComplexType_E<TestComplexType_L> | null, TestComplexType_E$JSON<TestComplexType_L> | null>(json, (json: TestComplexType_E$JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                return Optional_decode<TestComplexType_E<TestComplexType_L>, TestComplexType_E$JSON<TestComplexType_L>>(json, (json: TestComplexType_E$JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                    return TestComplexType_E_decode<TestComplexType_L, TestComplexType_L>(json, identity);
                });
            });
        });
    });
    return {
        a: a
    };
}

export type TestComplexType_Response = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
} & TagRecord<"TestComplexType_Response">;

export type TestComplexType_Response$JSON = {
    a?: TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Response_decode(json: TestComplexType_Response$JSON): TestComplexType_Response {
    const a = OptionalField_decode<TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>, TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>>(json.a, (json: TestComplexType_K$JSON<(TestComplexType_E$JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
        return TestComplexType_K_decode<(TestComplexType_E<TestComplexType_L> | null)[], (TestComplexType_E$JSON<TestComplexType_L> | null)[]>(json, (json: (TestComplexType_E$JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
            return Array_decode<TestComplexType_E<TestComplexType_L> | null, TestComplexType_E$JSON<TestComplexType_L> | null>(json, (json: TestComplexType_E$JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                return Optional_decode<TestComplexType_E<TestComplexType_L>, TestComplexType_E$JSON<TestComplexType_L>>(json, (json: TestComplexType_E$JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                    return TestComplexType_E_decode<TestComplexType_L, TestComplexType_L>(json, identity);
                });
            });
        });
    });
    return {
        a: a
    };
}
