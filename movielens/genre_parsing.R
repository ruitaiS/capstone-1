parse_genres <- function (genres){
  return(strsplit(genres, "\\|")[[1]])
}

genres_list <- parse_genres("Comedy|Crime|Mystery|Thriller")