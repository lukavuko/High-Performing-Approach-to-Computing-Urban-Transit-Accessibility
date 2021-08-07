
weights <- function(data, Amenity) {

  # point of interest type
  poi_type <- data %>%
                filter(type==Amenity) %>%
                select(poi_name, open_days, Total_hours, Rating, Total_Review)

  # replace zero with NA
  poi_type[poi_type == 0] <- NA
  missing_percentage <- colMeans(is.na(poi_type))
  paste('Missing Value %') 
  paste(missing_percentage)

  # fill NA with column mean 
  poi_type <- na_mean(poi_type)
  
  # normalize the features 
  normalize <- function(x) ((x - min(x)) / (max(x) - min(x)))
  Norm_poi <- poi_type %>% mutate_if(is.numeric, normalize)
  
  # Navie weighted index 
  return_df <- Norm_poi %>%
                mutate(Index=(open_days+Total_hours+Rating+Total_Review)/4) %>%
                select(poi_name,Index)

  return(return_df)
}

