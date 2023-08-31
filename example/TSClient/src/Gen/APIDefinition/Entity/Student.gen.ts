import { TagRecord } from "../../common.gen.js";
import {
    GenericID,
    GenericID2,
    GenericID2_JSON,
    GenericID3,
    GenericID3_JSON,
    GenericID3_decode,
    GenericID3_encode,
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

export type Student2_JSON = {
    id: Student2_ID_JSON;
    name: string;
};

export function Student2_decode(json: Student2_JSON): Student2 {
    const id = Student2_ID_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function Student2_encode(entity: Student2): Student2_JSON {
    const id = Student2_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student2_ID = GenericID2<Student2, GenericID<Student2>>;

export type Student2_ID_JSON = GenericID2_JSON<Student2_JSON, GenericID<Student2_JSON>>;

export function Student2_ID_decode(json: Student2_ID_JSON): Student2_ID {
    return json.rawValue as GenericID<Student2>;
}

export function Student2_ID_encode(entity: Student2_ID): Student2_ID_JSON {
    return {
        rawValue: entity as GenericID<Student2_JSON>
    };
}

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

export function Student3_encode(entity: Student3): Student3_JSON {
    const id = Student3_ID_encode(entity.id);
    const name = entity.name;
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

export function Student3_ID_encode(entity: Student3_ID): Student3_ID_JSON {
    return GenericID3_encode<Student3, Student3_JSON>(entity, Student3_encode);
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

export function Student4_encode(entity: Student4): Student4_JSON {
    const id = Student4_ID_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student4_ID = GenericID2<Student4, GenericID2<Student4, MyValue>>;

export type Student4_ID_JSON = GenericID2_JSON<Student4_JSON, GenericID2_JSON<Student4_JSON, MyValue_JSON>>;

export function Student4_ID_decode(json: Student4_ID_JSON): Student4_ID {
    return MyValue_decode(json.rawValue);
}

export function Student4_ID_encode(entity: Student4_ID): Student4_ID_JSON {
    return {
        rawValue: {
            rawValue: entity as MyValue_JSON
        }
    };
}
