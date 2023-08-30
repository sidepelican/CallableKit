import { TagRecord } from "../../common.gen.js";
import {
    GenericID,
    GenericID2,
    GenericID2_JSON,
    GenericID2_decode,
    GenericID3,
    GenericID3_JSON,
    GenericID3_decode,
    MyValue,
    MyValue_JSON,
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

export type Student2_ID = GenericID2<Student2, GenericID<Student2>>;

export type Student3 = {
    id: Student3_ID;
    name: string;
} & TagRecord<"Student3">;

export type Student3_JSON = {
    id: Student3_ID_JSON;
    name: string;
};

export function Student3_decode(json: Student3_JSON): Student3 {
    const id = Student3_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export type Student3_ID = GenericID3<Student3>;

export type Student3_ID_JSON = GenericID3_JSON<Student3_JSON>;

export function Student3_ID_decode(json: Student3_ID_JSON): Student3_ID {
    return GenericID3_decode<Student3, Student3_JSON>(json, Student3_decode);
}

export type Student4 = {
    id: Student4_ID;
    name: string;
} & TagRecord<"Student4">;

export type Student4_JSON = {
    id: Student4_ID_JSON;
    name: string;
};

export function Student4_decode(json: Student4_JSON): Student4 {
    const id = Student4_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export type Student4_ID = GenericID2<Student4, GenericID2<Student4, MyValue>>;

export type Student4_ID_JSON = GenericID2_JSON<Student4_JSON, GenericID2_JSON<Student4_JSON, MyValue_JSON>>;

export function Student4_ID_decode(json: Student4_ID_JSON): Student4_ID {
    return GenericID2_decode<
        Student4,
        Student4_JSON,
        GenericID2<Student4, MyValue>,
        GenericID2_JSON<Student4_JSON, MyValue_JSON>
    >(json, Student4_decode, (json: GenericID2_JSON<Student4_JSON, MyValue_JSON>): GenericID2<Student4, MyValue> => {
        return GenericID2_decode<
            Student4,
            Student4_JSON,
            MyValue,
            MyValue_JSON
        >(json, Student4_decode, MyValue_decode);
    });
}
