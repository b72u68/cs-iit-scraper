open Lwt
open Cohttp
open Cohttp_lwt_unix
open Soup

(* type declaration *)
type course =
    {
        code: string;
        title: string;
        description: string;
        preresiquites: string;
        (* the order is: [lecture, lab, credits]*)
        hours: string list;
        satisfies: string;
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
    let result =
        match l with
        | [] -> ""
        | h::t ->
                let trimmed_h = String.trim h in
                if String.length trimmed_h = 0 then concat_string t
                else trimmed_h ^ " " ^ (concat_string t)
    in
    String.trim result
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

(* cut title out of content *)
let get_content_without_title title full_content =
    let start_sub = String.length title in
    let sub_length = String.length full_content - start_sub in
    String.trim (String.sub full_content start_sub sub_length)
;;

(* parse course preresiquite(s) *)
let parse_preresiquite soup_course =
    let preresiquite_block = soup_course $ ".courseblockattr" in
    let soup_preresiquite = parse (to_string preresiquite_block) in
    let strong_node = soup_preresiquite $ "strong" in
    let strong_content = R.leaf_text strong_node in
    if compare "Prerequisite(s):" (String.trim strong_content) = 0 then
        let preresiquite_content_with_strong = concat_string (texts preresiquite_block) in
        get_content_without_title "Prerequisite(s):" preresiquite_content_with_strong
    else ""
;;

(* parse course credit hours *)
let parse_coursehours soup_course =
    let hour_block = soup_course $ ".hours" in
    let soup_hour = parse (to_string hour_block) in
    let span_blocks = to_list (soup_hour $$ "span" ) in
    let rec parse_span_blocks span_blocks =
        match span_blocks with
        | [] -> []
        | h::t ->
                let soup_span = parse (to_string h) in
                let strong_node = soup_span $ "strong" in
                let strong_content = R.leaf_text strong_node in
                let full_content = String.trim (concat_string (texts h)) in
                if String.compare "Lecture:" strong_content = 0 then
                    (get_content_without_title "Lecture:" full_content) :: (parse_span_blocks t)
                else if String.compare "Lab:" strong_content = 0 then
                    (get_content_without_title "Lab:" full_content) :: (parse_span_blocks t)
                else if String.compare "Credits:" strong_content = 0 then
                    (get_content_without_title "Credits:" full_content) :: (parse_span_blocks t)
                else
                    "" :: (parse_span_blocks t)
    in
    parse_span_blocks span_blocks
;;

(* parse course satisfies *)
let parse_coursesatisfies soup_course =
    let courseattr_blocks = soup_course $$ ".courseblockattr" in
    let courseattr_block_list = to_list courseattr_blocks in
    let rec parse_satisfies l =
        match l with
        | [] -> ""
        | h::t ->
                let soup_attr = parse (to_string h) in
                let strong_node = soup_attr $ "strong" in
                let strong_content = R.leaf_text strong_node in
                let full_content = String.trim (concat_string (texts h)) in
                if String.compare "Satisfies:" strong_content = 0 then
                    get_content_without_title "Satisfies:" full_content
                else parse_satisfies t
    in
    parse_satisfies courseattr_block_list
;;

(* parse for each course in HTML body *)
let parse_course_info_from_body body =
    let course_nodes = parse body $$ ".courseblock" in
    let course_node_list = to_list course_nodes in
    let rec get_course_info_list l =
        match l with
        | [] -> []
        | h::t ->
            let soup_course = parse (to_string h) in
            let coursecode = parse_coursecode soup_course in
            let coursetitle = parse_coursetitle soup_course in
            let coursedesc = parse_courseblockdesc soup_course in
            let coursepreresiquites = parse_preresiquite soup_course in
            let coursehours = parse_coursehours soup_course in
            let coursesatisfies = parse_coursesatisfies soup_course in
            let course_info =
                {
                    code = coursecode;
                    title = coursetitle;
                    description = coursedesc;
                    preresiquites = coursepreresiquites;
                    hours = coursehours;
                    satisfies = coursesatisfies;
                }
            in
            course_info :: (get_course_info_list t)
    in
    get_course_info_list course_node_list
;;

let ugrad_cs_course_list = parse_course_info_from_body ugrad_body;;
let grad_cs_course_list = parse_course_info_from_body grad_body;;
