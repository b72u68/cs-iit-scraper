open Lwt
open Cohttp
open Cohttp_lwt_unix
open Soup

(* type declaration *)
type credit_hours = {
    lecture: string;
    lab: string;
    credits: string;
};;

type course =
    {
        code: string;
        title: string;
        description: string;
        preresequites: string;
        hours: credit_hours;
        satisfies: string list;
    }
;;

(* base urls *)
let cs_ugrad_url = "http://bulletin.iit.edu/undergraduate/courses/cs/"
let cs_grad_url = "http://bulletin.iit.edu/graduate/courses/cs/"
let past_courses = "http://www.cs.iit.edu/past_courses.html"

(* get HTML body of given url *)
let get_body (uri_string: string): string Lwt.t =
    Client.get (Uri.of_string uri_string) >>= fun (_, body) ->
        Cohttp_lwt.Body.to_string body
;;

(* initialize the HTML body of each page*)
let ugrad_body: string = Lwt_main.run (get_body cs_ugrad_url);;
let grad_body: string = Lwt_main.run (get_body cs_grad_url);;


(* concate a string list together *)
let rec concat_string (l: string list) : string =
    match l with
    | [] -> ""
    | h::t -> h ^ " " ^ (concat_string t)
;;

(* parse course information using the given classname *)
let parse_course_info soup classname =
    let courseinfo_list = trimmed_texts (soup $ classname) in
    concat_string courseinfo_list
;;

(* parse course code *)
let parse_coursecode soup = parse_course_info soup ".coursecode";;

(* parse course title *)
let parse_coursetitle soup = parse_course_info soup ".coursetitle";;

(* parse course description *)
let parse_courseblockdesc soup = parse_course_info soup ".courseblockdesc";;

(* parse course preresequite(s) *)
let parse_preresequite soup_course =
    let preresequite_block = soup_course $ ".courseblockattr" in
    let soup_preresequite = parse (to_string preresequite_block) in
    let strong_node = soup_preresequite $ "strong" in
    let strong_content = R.leaf_text strong_node in
    if compare "Prerequisite(s):" (String.trim strong_content) = 0 then
        let preresequite_content_with_strong = concat_string (texts preresequite_block) in
        let start_sub = String.length "Prerequisite(s):  " in
        let sub_length = String.length preresequite_content_with_strong - start_sub in
        String.trim (String.sub preresequite_content_with_strong start_sub sub_length)
    else ""
;;

(* parse for each course in HTML body *)
let () =
    parse ugrad_body $$ ".courseblock" |> iter (fun a ->
        let soup_course = parse (to_string a) in
        let preresequite = parse_preresequite soup_course in
        print_endline (preresequite))
;;
