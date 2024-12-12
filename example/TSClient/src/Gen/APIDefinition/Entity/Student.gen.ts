import { TagRecord, identity } from "../../common.gen.js";
import {
    GenericID,
    GenericID2,
    GenericID2$JSON,
    GenericID2_decode,
    GenericID2_encode,
    GenericID3,
    GenericID3$JSON,
    GenericID3_decode,
    GenericID3_encode,
    GenericID4,
    MyValue,
    MyValue$JSON,
    MyValue_decode
} from "./GenericID.gen.js";

export type Student = {
    id: Student_ID;
    name: string;
} & TagRecord<"Student">;

export type Student_ID = GenericID<Student>;

export type Student2 = {
    id: Student2_ID;
    name: string;
} & TagRecord<"Student2">;

export type Student2$JSON = {
    id: Student2_ID$JSON;
    name: string;
};

export function Student2_decode(json: Student2$JSON): Student2 {
    const id = Student2_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function Student2_encode(entity: Student2): Student2$JSON {
    const id = Student2_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student2_ID = GenericID2<Student2, string>;

export type Student2_ID$JSON = GenericID2$JSON<Student2$JSON, string>;

export function Student2_ID_decode(json: Student2_ID$JSON): Student2_ID {
    return GenericID2_decode<
        Student2,
        Student2$JSON,
        string,
        string
    >(json, Student2_decode, identity);
}

export function Student2_ID_encode(entity: Student2_ID): Student2_ID$JSON {
    return GenericID2_encode<
        Student2,
        Student2$JSON,
        string,
        string
    >(entity, Student2_encode, identity);
}

export type Student3 = {
    id: Student3_ID;
    name: string;
} & TagRecord<"Student3">;

export type Student3$JSON = {
    id: Student3_ID$JSON;
    name: string;
};

export function Student3_decode(json: Student3$JSON): Student3 {
    const id = Student3_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function Student3_encode(entity: Student3): Student3$JSON {
    const id = Student3_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student3_ID = GenericID3<Student3>;

export type Student3_ID$JSON = GenericID3$JSON<Student3$JSON>;

export function Student3_ID_decode(json: Student3_ID$JSON): Student3_ID {
    return GenericID3_decode<Student3, Student3$JSON>(json, Student3_decode);
}

export function Student3_ID_encode(entity: Student3_ID): Student3_ID$JSON {
    return GenericID3_encode<Student3, Student3$JSON>(entity, Student3_encode);
}

export type Student4 = {
    id: Student4_ID;
    name: string;
} & TagRecord<"Student4">;

export type Student4$JSON = {
    id: Student4_ID$JSON;
    name: string;
};

export function Student4_decode(json: Student4$JSON): Student4 {
    const id = Student4_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function Student4_encode(entity: Student4): Student4$JSON {
    const id = Student4_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student4_ID = GenericID2<Student4, GenericID2<Student4, MyValue>>;

export type Student4_ID$JSON = GenericID2$JSON<Student4$JSON, GenericID2$JSON<Student4$JSON, MyValue$JSON>>;

export function Student4_ID_decode(json: Student4_ID$JSON): Student4_ID {
    return GenericID2_decode<
        Student4,
        Student4$JSON,
        GenericID2<Student4, MyValue>,
        GenericID2$JSON<Student4$JSON, MyValue$JSON>
    >(json, Student4_decode, (json: GenericID2$JSON<Student4$JSON, MyValue$JSON>): GenericID2<Student4, MyValue> => {
        return GenericID2_decode<
            Student4,
            Student4$JSON,
            MyValue,
            MyValue$JSON
        >(json, Student4_decode, MyValue_decode);
    });
}

export function Student4_ID_encode(entity: Student4_ID): Student4_ID$JSON {
    return GenericID2_encode<
        Student4,
        Student4$JSON,
        GenericID2<Student4, MyValue>,
        GenericID2$JSON<Student4$JSON, MyValue$JSON>
    >(entity, Student4_encode, (entity: GenericID2<Student4, MyValue>): GenericID2$JSON<Student4$JSON, MyValue$JSON> => {
        return GenericID2_encode<
            Student4,
            Student4$JSON,
            MyValue,
            MyValue$JSON
        >(entity, Student4_encode, identity);
    });
}

export type Student5 = {
    id: Student5_ID;
    name: string;
} & TagRecord<"Student5">;

export type Student5_ID = GenericID4<Student4, string>;
