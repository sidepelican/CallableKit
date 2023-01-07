import { TagRecord } from "../../common.js";
import {
    GenericIDz,
    GenericIDz_JSON,
    GenericIDz_decode,
    GenericIDz_encode
} from "./GenericID.js";

export type Student = {
    id: Student_IDz;
    name: string;
} & TagRecord<"Student">;

export type Student_JSON = {
    id: Student_IDz_JSON;
    name: string;
};

export function Student_decode(json: Student_JSON): Student {
    const id = Student_IDz_decode(json.id);
    const name = json.name;
    return {
        id: id,
        name: name
    };
}

export function Student_encode(entity: Student): Student_JSON {
    const id = Student_IDz_encode(entity.id);
    const name = entity.name;
    return {
        id: id,
        name: name
    };
}

export type Student_IDz = GenericIDz<Student>;

export type Student_IDz_JSON = GenericIDz_JSON<Student_JSON>;

export function Student_IDz_decode(json: Student_IDz_JSON): Student_IDz {
    return GenericIDz_decode<Student, Student_JSON>(json, Student_decode);
}

export function Student_IDz_encode(entity: Student_IDz): Student_IDz_JSON {
    return GenericIDz_encode<Student, Student_JSON>(entity, Student_encode);
}
