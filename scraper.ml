open Lwt
open Cohttp
open Cohttp_lwt_unix
open Soup

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

(* parse course description *)
let parse_courseblockdesc soup : string =
    let coursedesc_list = texts (soup $ ".courseblockdesc") in
    let rec concat_desc (l: string list) : string =
        match l with
        | [] -> ""
        | h::t -> h ^ (concat_desc t)
    in
    concat_desc coursedesc_list
;;

(* parse course preresiquite(s) *)
let parse_courseblockattr soup : string = ""
;;

(* parse for each course in HTML body *)
let () =
    parse ugrad_body $$ ".courseblock" |> iter (fun a ->
        let soup_a = parse (to_string a) in
        let coursecode = R.leaf_text (soup_a $ ".coursecode") in
        let coursetitle = R.leaf_text (soup_a $ ".coursetitle") in
        let coursedesc = parse_courseblockdesc soup_a in
        print_endline (coursecode ^ "\n" ^ coursetitle ^ "\n" ^ coursedesc))
;;
