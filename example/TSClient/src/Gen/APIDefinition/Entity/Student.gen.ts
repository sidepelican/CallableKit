import { TagRecord } from "../../common.gen.js";
import { GenericID, GenericID2 } from "./GenericID.gen.js";

export type Student = {
    id: Student_ID;
    name: string;
} & TagRecord<"Student">;

export type Student_ID = GenericID<Student>;

export type Student_ID2 = GenericID2<Student, number>;
