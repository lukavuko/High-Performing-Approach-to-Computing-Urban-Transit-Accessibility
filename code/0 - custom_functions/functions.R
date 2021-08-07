## CUSTOM PROJECT FUNCTIONS
# This file stores base functions used for the project
# These include functions for scoring, mapping, wrangling, and data normalization 
# Developers: Luka Vukovic, Rain Shen, Graham Kerford, Yuxuan Cui


############################################################
## NORMALIZATION FUNCTIONS
############################################################

# Normalizes a vector to a custom range [x,y] with log normalization as an option
# Default normalization range is 0.01 to 0.99 to avoid zero division in later functions.
# Input is a numeric vector 
# Output is a normalized numeric vector
normalize_vec <- function(vec, x = 0.01, y = 0.99, log = FALSE) {
  
  if (log == TRUE) { vec <- log(vec) }
  norm_v <- (vec - min(vec))/(max(vec) - min(vec))
  custom_norm_v <- norm_v*(y - x) + x
  custom_norm_v
}

# Normalize all numeric columns in a dataframe to a custom range [x,y] with log normalization as an option
# Default normalization range is 0.01 to 0.99 to avoid zero division in later functions.
# Input is a dataframe 
# Output is a dataframe with numeric columns normalized
normalize_df <- function(df, x = 0.01, y = 0.99, log = FALSE) {
  num_cols <- which(sapply(df, is.numeric)) # numeric columns
  normed <- sapply(df[num_cols], normalize_vec, x = x, y = y, log = log)
  df[num_cols] <- (normed)
  df
}


############################################################
## SCORING FUNCTIONS (Transit Accessibility Measure)
############################################################

# Transit Accessibility Measure Scoring Function
# Input: a dataframe with columns: avg_time, sd_time, and optionally weights
# output: a new dataframe that includes the accessibility score.
# The score is the inverse of the "worst case" trip time from 1 point to the
# nearest 1, 2, 3, ... , n amenities depending on how many amenities you want to consider.
# The score could optionally include weights for each amenity and be
# log normalized to correct skewness in the distribution. Users may also set
# what range they want the score to be in by specifying x and y values which are defaulted to 0.01 and 0.99
# The score equation is: SUM [i..n] (1/(mean_traveltime_i + 2*std_traveltime_j) + 1/...  + 1/...   ...))

sum_score_fxn <- function(df, nearest_n = NULL, weight = FALSE, log_normalize_score = FALSE, x = 0.01, y = 0.99) {

  # filter nearest_n rows
  if (!is.null(nearest_n)) {
    
    # filter only the nearest_n travel times
    df <- df %>%
      group_by(fromId, type) %>%
      summarize(avg_time = na.omit(sort(avg_time)[1:nearest_n]),
                sd_time = sd_time[which(avg_time == na.omit(sort(avg_time)[1:nearest_n]))],
                weight = weight[which(avg_time == na.omit(sort(avg_time)[1:nearest_n]))])
    
    # compute score with or without weight 
    if (weight == TRUE) {
      df$unique_score <- (1+df$weight) / (df$avg_time + 2*df$sd_time)
    } else {
      df$unique_score <- 1 / (df$avg_time + 2*df$sd_time)
    }
    
  # include all rows
  } else if (is.null(nearest_n)) {
    
    #compute scores with or without weight 
    if (weight == TRUE) {
      df$unique_score <- (1 + df$weight) / (df$avg_time + 2*df$sd_time)
    } else {
      df$unique_score <- 1 / (df$avg_time + 2*df$sd_time)
    }
    
  }

  # sum the scores and normalize
  # if nearest_n == 1 the results will not change
  df <- df %>% 
    # group on unique trips and amenity types
    group_by(fromId, type) %>% 
    
    # sum the scores - only makes a difference is nearest_n > 1
    summarize(score = sum(unique_score)) %>%
    
    # group by types to normalize by the types
    group_by(type) %>%
    
    # normalize and add column labels for the score
    mutate(score = normalize_vec(score, x = x, y = y, log = log_normalize_score),
           weight = as.factor(ifelse(weight == FALSE, 'no', 'yes')),
           nearest_n = as.factor(ifelse(is.null(nearest_n), 'all', as.character(nearest_n))))
  
  df
}


############################################################
## NA SUBSTITUTION FUNCTIONS
############################################################

# Expands a grid of NA values based on the factors of missing values in a dataframe.
# This is useful if you want NA values regions to be represented on a map.
# For example, each origin ID expects 32 values, but in many cases only 8 or 16
# are present. In that case we would expand a grid using the missing factors to
# reincorporate those NA values into the frame. 
# Input: vector of row IDs that need NAs
# Output: Rows with the ID and NA values under the factors.

NA_grid_maker <- function(id, df, frame_type) {

  # create NA rows to append via expand.grid (creates a row for every factor combination)
  if (frame_type == 'efficiency') {

    # it doesn't really expand a grid because there are no factors! can be updated in the future
    NA_rows <- expand.grid('fromId' = id, 'mean_score' = NA,
                           'pop' = NA, 'amn_dens' = NA,
                           'trafficScore' = NA, 'need' = NA,
                           'eff' = NA, stringsAsFactors = TRUE)
  } else {
    # get all amenities
    all_amenities <- as.character(unique(df$type))
    # get missing amenities by indexing the present amenities at each fromId
    missing_amenities <- setdiff(all_amenities, unique(df$type[df$fromId == id]))
  } 
  
  if (frame_type == 'score') {
    
    NA_rows <- expand.grid('fromId' = id, 'type' = missing_amenities,
                            'weight' = as.character(unique(df$weight)),
                            'nearest_n' = as.character(unique(df$nearest_n)),
                            'score' = NA, stringsAsFactors = TRUE)

  } else if (frame_type == 'isochrone') {
    
    NA_rows <- expand.grid('fromId' = id, 'type' = missing_amenities,
                           'time_groups' = NA,  stringsAsFactors = TRUE)
  } 

  NA_rows

}

# Function that calls on grid expander and fills the dataframe with NA values where
# there needs to be a equal number of rows for each ID.
# Users must specify the frame_type since our code is structured for 3 different frames:
# c('efficiency', 'score', and 'isochrone')
# A vector of Custom IDs (custom_idx) can be optionally specified for adding ID
# values not found in the original frame, otherwise NAs are only filled
# for ID values existing in the dataframe.

NA_table_filler <- function(df, custom_idx = NULL, frame_type) {
  
  # count each fromId occurence
  fromId_counts <- df %>% group_by(fromId) %>% mutate(n = n())
  x <- max(fromId_counts$n)

  # if no custom indx is provided just fill
  # other wise fill and then add missing index rows
  if (is.null(custom_idx)) {

    # create a fromId array using Ids that don't meet the [x] count requirement
    id_arr <- array(unique(fromId_counts[fromId_counts$n < x, ]$fromId))

  } else {

    # fill first then use custom index
    df <- NA_table_filler(df, frame_type = frame_type)
    # use a custom index of fromIds (for example those missing from the frame)
    id_arr <- custom_idx

  }

  # get the NA filler rows
  filler_rows <- rbindlist(apply(id_arr, MARGIN = 1,
                                  FUN = NA_grid_maker,
                                  df = df,
                                  frame_type = frame_type))

  # append to input dataframe sort them
  df <- rbindlist(list(df, filler_rows), use.names = TRUE) 
  
  if (frame_type == 'score') {
    df <- df %>% arrange(fromId, type, nearest_n, weight)
  } else if (frame_type == 'isochrone'){
    df <- df %>% arrange(fromId, type)
  } else if (frame_type == 'efficiency') {
    df <- df %>% arrange(fromId)
  }
  
  df
}


# A function that checks how many rows are missing in a given accessibility measure data frane
# and returns the IDs that are missing in an array called missing_blocks.
# The missing blocks output object is a vector of IDs that is typically input as
# as custom index to the Na_table_filler function. Otherwise, this simply performs
# a user friendly check to see if values are missing.
# Input: A frame with a `fromId` column for all origin IDs,
# a frame containing the original IDs in an `id` column,
# how many rows each ID should have (depends on your factors, for example,
# if you have 2 factors with 3 options this values needs to be 6 = 2*3 so there are 6 rows for each ID),
# and the frame_type which can be optionally specified.
# Output: vector of missing IDs from the original frame and print information on what % of values are missing.

check_rows <- function(check_frame, origins_frame, rows_per_dissemination_block, frame_type = 'Frame type not specified') {
  
  print(paste(frame_type))
  cat(paste0('\n')) # line break

  # HOW MANY ROWS TO FILL IN SCORES?
  n <- nrow(check_frame)
  N <- uniqueN(check_frame$fromId) * rows_per_dissemination_block
  print(paste(glue('{n} of {N} rows filled ({round((n/N)*100, 2)}%)')))
  print(paste(N - n, 'existing IDs to fill.'))
  cat(paste0('\n')) # line break

  # HOW MANY ROWS TO ADD IN SCORES?

  # take the difference of IDs in both frames
  # missing blocks are IDs that should appear in the frame but dont.
  missing_blocks <- array(setdiff(origins_frame$id, check_frame$fromId))
  total_expected <- n + length(missing_blocks) * rows_per_dissemination_block
  print(paste(glue('{n} of {total_expected} rows filled ({round((n/total_expected)*100, 2)}%)')))
  print(paste(length(missing_blocks)*rows_per_dissemination_block, 'IDs to add'))

  return(missing_blocks)
}


############################################################
## RUNNING AVERAGE FUNCTIONS
############################################################


# Function that calculates the mean traffic count within 0.0675 degrees of each block in Vancouver, Canada
## CHECK1 i'm not sure if 0.0675 is really 5000m, it seems more like it's 7km??
## CHECK2 i'm not sure if the function should be calling on a global object. Can we make it more "functional" by nature?

db_trafic <- function(row){
  mean(filter(traffic_data,
                trafic_data$LATITUDE <= (as.numeric(row["lat"])+0.0675) & 
                trafic_data$LATITUDE >= (as.numeric(row["lat"])-0.0675) & 
                trafic_data$LONGITUDE <= (as.numeric(row["lon"])+0.0675) & 
                trafic_data$LONGITUDE >= (as.numeric(row["lon"])-0.0675))$TrafficCount) 
}


# Function that iterates Through each row of a sparsly filled traffic information dataframe,
# and returns the most recent traffic information.

is_NA <- function(row, col = 21) {
  if (is.na(row[col+3]) & col>0) {
    is_NA(row = row, col = col-1)
  } else if (col == 0 ){
    0
  } else {
    row[col+3]  
  }
}

# Used with apply statements to parse sparsely filled traffic dataframes

getAll_Data <- function(row){
  is_NA(row)
}


############################################################
## VISUALIZATION FUNCTIONS
############################################################

# Function to plot 2 score set distributions by type for exploratory comparison
# Input: two accessibility measures score frames, and optional figure titles
# Output: Two density plots comparing the distribution of scores

plot_densities <- function(score_frame1, score_frame2, titl1 = 'Plot 1', titl2 = 'Plot 2') {
  x <- score_frame1 %>%
        ggplot(aes(x = score, color = type)) +
        geom_density() +
        egg::theme_article() +
        theme(aspect.ratio = 0.3) +
        ggtitle(titl1)
  y <- score_frame2 %>%
        ggplot(aes(x = score, color = type)) +
        geom_density() +
        egg::theme_article() +
        theme(aspect.ratio = 0.3)+
        ggtitle(titl2)
  gridExtra::grid.arrange(x, y)
}


## MAP MAKER FUNCTIONS
# We have 3 primary map maker functions. These use leaflet to generate choropleths for difference accessibility measrues.
# All functions by default output the map to the working directory, to turn this off set view_map to TRUE
# and it will be displayed in R instead of being saved.

# Score map maker:
# Input: data (dataframe) with columns:
    # $score,
    # $DBUID (dissemination block unique ID),
    # $pop (block population), 
    # $type (amenity type),
    # $weight (amenity weight),
    # $nearest_n (how many amenities to consider),
# bus_data (coordinates of bus stops) with columns $stop_name, $stop_id, $latitude, $longitude
# amenity (which amenity type to consider in the map. Value must exist in the $type column),
# weight (whether to include weights, Yes/No. Value must exist in the $weight column),
# nearest_n (how many amenities to consider.Value must exist in the $nearest_n column),
# add_stop = TRUE or FALSE, whether to plot the stop coordinates
# output directory = where to save the renderd map (only if vew_map == FALSE)

# Output: rendered html map (when view == FALSE)

map_maker_scores <- function(data, bus_data, amenity, weight, nearest_n, add_stop, output_dir, view_map = FALSE) {
  
  amn_name <- amenity %>%
    str_to_title() %>%
    str_replace_all('Or', 'or') %>%
    str_replace('And', 'and') %>%
    str_replace('/Performance', '')
  
  # subset info
  polyg_subset <- data[data$type == amenity & data$weight == weight & data$nearest_n == nearest_n, ]
  
  # score vector
  score_vec <- polyg_subset$score
  
  # colour palette 
  Rd2Gn <- c("#e30606", "#fd8d3c", "#ffe669", "#cdff5e", "#64ed56")
  pal_fun <- colorQuantile(palette = Rd2Gn, NULL, n = 5)
  
  # popup # percentile(score_vec),
  percentile <- ecdf(score_vec)
  p_popup <- paste0("<h3><strong>Accessibility Percentile: ", round(percentile(score_vec), 2)*100, '%',"</strong></h3>", 
                    "<i> To the nearest ", nearest_n, ' ', amn_name, "</i>",
                    "<br><br>Raw Score: ", round(score_vec, 2),
                    "<br>Block Population: ", polyg_subset$pop,
                    "<br>Block ID: ", polyg_subset$DBUID)
  
  map <- leaflet(data = polyg_subset) %>%
    addPolygons(
      stroke = FALSE,  # remove polygon borders
      fillColor = ~pal_fun(score_vec), # set fill colour with pallette fxn from aboc
      fillOpacity = 0.6, smoothFactor = 0.5, # aesthetics
      popup = p_popup) %>% # add message popup to each block
    addTiles() %>%
    setView(lng = -122.8, lat = 49.2, zoom = 11) %>%
    addLegend("bottomleft",  # location
              pal=pal_fun,    # palette function
              values=~score_vec,  # value to be passed to palette function
              title = glue('{amn_name} Transit Access'))

  if (add_stop==TRUE) {

    stop_popup<-paste0("<strong>", bus_data$stop_name, "</strong>",
                     "<br>Stop: <strong>",bus_data$stop_id,"</strong>")

    map <- map %>% addCircles(data=bus_data,~longitude, ~latitude,
                              weight = 0.9, radius=6,
                              color="#0073B2", stroke = TRUE,
                              fillOpacity = 0.8, popup = stop_popup)
    
    file_name <- glue('{amn_name} - wt({weight}) - n({str_to_upper(nearest_n)}) - stops(yes)')
    print(paste('Current Map:', file_name))
  } else {
    file_name <- glue('{amn_name} - wt({weight}) - n({str_to_upper(nearest_n)}) - stops(no)')
    print(paste('Current Map:', file_name))
  }
  
  if (view_map == TRUE) {
    return(map)
  } else {
    mapshot(map, url = glue("{getwd()}/{output_dir}/{file_name}.html"))
  }
  
}



# Isochrone map maker:
# Input: data (dataframe) with columns:
    # $time_groups (isochrone time group),
    # $DBUID (dissemination block unique ID),
    # $pop (block population), 
    # $type (amenity type),
# bus_data (coordinates of bus stops) with columns $stop_name, $stop_id, $latitude, $longitude
# amenity (which amenity type to consider in the map. Value must exist in the $type column),
# add_stop = TRUE or FALSE, whether to plot the stop coordinates
# output directory = where to save the renderd map (only if vew_map == FALSE)

# Output: rendered html map (when view == FALSE)
map_maker_isochrone <- function(data, bus_data, amenity, add_stop, output_dir, view_map = FALSE) {
  
  amn_name <- amenity %>%
    str_to_title() %>%
    str_replace_all('Or', 'or') %>%
    str_replace('And', 'and') %>%
    str_replace('/Performance', '')
   
  # subset info
  polyg_subset <- data[data$type == amenity, ]
  
  # score vector
  time_groups <- polyg_subset$time_groups
  
  # colour palette 
  pal_fun <- colorFactor(
    palette = c("#3ef000", "#c5eb00", "#fbff00", "#e9cb00", "#e78600", "#e44200", "#e20000"),
    levels = sort(unique(polyg_subset$time_groups))
  )
  
  p_popup <- paste0("<h3>Max Time: <strong>", time_groups, " minutes</strong></h3>",
                    "To the nearest: ", amn_name, 
                    "<br><br>Block Population: ", polyg_subset$pop,
                    "<br>Block ID: ", polyg_subset$DBUID)
  
  map <- leaflet(data = polyg_subset) %>%
    addPolygons(
      stroke = FALSE,  # remove polygon borders
      fillColor = ~pal_fun(time_groups), # set fill colour with pallette fxn from aboc
      fillOpacity = 0.7, smoothFactor = 0.5, # aesthetics
      popup = p_popup) %>% # add message popup to each block
    addTiles() %>%
    setView(lng = -122.8, lat = 49.2, zoom = 11) %>%
    addLegend("bottomleft",  # location
              pal=pal_fun,    # palette function
              values=~time_groups,  # value to be passed to palette function
              title = glue('{amn_name} Transit Access'))

  if (add_stop==TRUE) {
      
    stop_popup<-paste0("<strong>", bus_data$stop_name, "</strong>",
                     "<br>Stop: <strong>",bus_data$stop_id,"</strong>")

    map <- map %>% addCircles(data=bus_data,~longitude, ~latitude,
                              weight = 0.9, radius=6,
                              color="#0073B2", stroke = TRUE,
                              fillOpacity = 0.8, popup = stop_popup)
    
    file_name <- glue('{amn_name} - isochrone - stops(yes)')
    print(paste('Current Map:', file_name))

  } else {
    file_name <- glue('{amn_name} - isochrone - stops(no)')
    print(paste('Current Map:', file_name))
  }

  if (view_map == TRUE) {
    return(map)
  } else {
    mapshot(map, url = glue("{getwd()}/{output_dir}/{file_name}.html"))
  }
  
}



# Efficiency map maker with continuous colour scheme:
# Input: data (dataframe) with columns:
    # $eff (efficiency score),
    # $DBUID (dissemination block unique ID),
    # $pop (block population), 
    # $type (amenity type),
    # $mean_score (accessibility score)
    # $traffic_score (traffic score)
    # $amn_dens (amenity density)
# bus_data (coordinates of bus stops) with columns $stop_name, $stop_id, $latitude, $longitude
# amenity (which amenity type to consider in the map. Value must exist in the $type column),
# add_stop = TRUE or FALSE, whether to plot the stop coordinates
# output directory = where to save the renderd map (only if vew_map == FALSE)

# Output: rendered html map (when view == FALSE)

map_maker_efficiency_cont <- function(data, bus_data, add_stop = TRUE, mapTitle = "Continuous Efficiency", output_dir, view_map = FALSE) {
    
  # subset info
  polyg_subset <- data
  
  # variable vector
  variable <- polyg_subset$eff
  
  # colour palette 
  Bl2Rd <- c("#FF0000", "#FA8072", "#fcd7db", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#ADDFFF", "#1589FF", "#0000FF")
  pal_fun <- colorNumeric(palette = Bl2Rd, NULL, n = 10)
  
   p_popup <- paste0("<h3>Efficiency Score: <strong>", round(variable, 2), "</strong></h3>",
                    "<i> The closer to zero, the better.</i>", "<br><br>",
                    "<strong>Accessibility Score: ", round(polyg_subset$mean_score, 2),"</strong>",
                    "<br><strong>Needs Score:  ", round((1/3)*(polyg_subset$pop+ polyg_subset$trafficScore+ polyg_subset$amn_dens), 2), "</strong>",
                    "<br><br>Population: ",  round(polyg_subset$pop, 2),
                    "<br>Traffic: ",  round(polyg_subset$trafficScore, 2),
                    "<br>Amenity density: ",  round(polyg_subset$amn_dens, 2),
                    "<br>Block ID: ", polyg_subset$DBUID,
                    "<br><br>Notes: <br>",
                    "<i>Efficiency = Accessibility - Needs</i>", "<br>",
                    "<i>Needs = mean(Population + Traffic + Amenity denisty)</i>")
  
  map <- leaflet(data = polyg_subset) %>%
    addPolygons(
      stroke = FALSE,  # remove polygon borders
      fillColor = ~pal_fun(variable), # set fill colour with pallette fxn from aboc
      fillOpacity = 0.6, smoothFactor = 0.5, # aesthetics
      popup = p_popup) %>% # add message popup to each block
    addTiles() %>%
    setView(lng = -122.8, lat = 49.2, zoom = 11) %>%
    addLegend("bottomleft",  # location
              pal=pal_fun,    # palette function
              values=~variable,  # value to be passed to palette function
              title = glue('{mapTitle} Map'))
  

  if (add_stop==TRUE) {
    
   stop_popup<-paste0("<strong>", bus_data$stop_name, "</strong>",
                     "<br>Stop: <strong>",bus_data$stop_id,"</strong>")

    map <- map %>% addCircles(data=bus_data,~longitude, ~latitude,
                              weight = 0.9, radius=6,
                              color="#a7a7a7", stroke = TRUE,
                              fillOpacity = 0.8, popup = stop_popup)
    
    file_name <- glue('{mapTitle} - stops(yes)')
    print(paste('Current Map:', file_name))

  } else {
    file_name <- glue('{mapTitle} - stops(no)')
    print(paste('Current Map:', file_name))
  }
  

  if (view_map == TRUE) {
    return(map)
  } else {
    mapshot(map, url = glue("{getwd()}/{output_dir}/{file_name}.html"))
  }
  
}


# Efficiency map maker with discrete colour scheme:
# Input: data (dataframe) with columns:
    # $eff (efficiency score),
    # $DBUID (dissemination block unique ID),
    # $pop (block population), 
    # $type (amenity type),
    # $mean_score (accessibility score)
    # $traffic_score (traffic score)
    # $amn_dens (amenity density)
# bus_data (coordinates of bus stops) with columns $stop_name, $stop_id, $latitude, $longitude
# amenity (which amenity type to consider in the map. Value must exist in the $type column),
# add_stop = TRUE or FALSE, whether to plot the stop coordinates
# output directory = where to save the renderd map (only if vew_map == FALSE)

# Output: rendered html map (when view == FALSE)

map_maker_efficiency_discrete <- function(data, bus_data, add_stop = TRUE, mapTitle = "Discrete Efficiency", output_dir, view_map = FALSE) {
  
  # subset info
  polyg_subset <- data
  
  # variable vector
  variable <- polyg_subset$eff
  
  # colour palette 
  Bl2Rd <- c("#FA8072", "#fcd7db", "#FFFFFF", "#FFFFFF",  "#FFFFFF", "#FFFFFF", "#ADDFFF", "#1589FF")
  pal_fun <- colorQuantile(palette = Bl2Rd, NULL, n = 8)
  
  # popup # percentile(score_vec),
  #percentile <- ecdf(polyg_subset$mean_score)
  p_popup <- paste0("<h3>Efficiency Score: <strong>", round(variable, 2), "</strong></h3>",
                    "<i> The closer to zero, the better.</i>", "<br><br>",
                    "<strong>Accessibility Score: ", round(polyg_subset$mean_score, 2),"</strong>",
                    "<br><strong>Needs Score:  ", round((1/3)*(polyg_subset$pop+ polyg_subset$trafficScore+ polyg_subset$amn_dens), 2), "</strong>",
                    "<br><br>Population: ",  round(polyg_subset$pop, 2),
                    "<br>Traffic: ",  round(polyg_subset$trafficScore, 2),
                    "<br>Amenity density: ",  round(polyg_subset$amn_dens, 2),
                    "<br>Block ID: ", polyg_subset$DBUID,
                    "<br><br>Notes: <br>",
                    "<i>Efficiency = Accessibility - Needs</i>", "<br>",
                    "<i>Needs = mean(Population + Traffic + Amenity denisty)</i>")
  
  map <- leaflet(data = polyg_subset) %>%
    addPolygons(
      stroke = FALSE,  # remove polygon borders
      fillColor = ~pal_fun(variable), # set fill colour with pallette fxn from aboc
      fillOpacity = 0.6, smoothFactor = 0.5, # aesthetics
      popup = p_popup) %>% # add message popup to each block
    addTiles() %>%
    setView(lng = -122.8, lat = 49.2, zoom = 11) %>%
    addLegend("bottomleft",  # location
              pal=pal_fun,    # palette function
              values=~variable,  # value to be passed to palette function
              title = glue('{mapTitle} Map'))  
  
  if (add_stop==TRUE) {

    stop_popup<-paste0("<strong>", bus_data$stop_name, "</strong>",
                     "<br>Stop: <strong>",bus_data$stop_id,"</strong>")

    map <- map %>% addCircles(data=bus_data,~longitude, ~latitude,
                              weight = 0.9, radius=6,
                              color="#a7a7a7", stroke = TRUE,
                              fillOpacity = 0.8, popup = stop_popup)
    
    file_name <- glue('{mapTitle} - stops(yes)')
    print(paste('Current Map:', file_name))
    
  } else {
    file_name <- glue('{mapTitle} - stops(no)')
    print(paste('Current Map:', file_name))
  }

  if (view_map == TRUE) {
    return(map)
  } else {
    mapshot(map, url = glue("{getwd()}/{output_dir}/{file_name}.html"))
  }
  
}