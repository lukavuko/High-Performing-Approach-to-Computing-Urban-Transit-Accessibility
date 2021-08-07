# Project Code Directory

Project code is organized in the chronological steps one would take to reproduce out project. Each directory is summarized below for its functions:
0)  Custom Functions:
    - Contains all custom functions used for the project such as functions for normalizing vectors, data tables, inserting NA values into score matrices, and map building visualization functions to name a few.
1) Raw Wrangling:
    - Contains code for wrangling the raw data. This was primarily for filtering Canadian Census data to keep amenities and dissemination blocks only within the Vancouver metropolitan area. It also contains a wrangling file for Vancouver's traffic data which was used in for the efficiency model later developed.
2) Travel Time Matrix Computation
    - Contains code for computing transit times from origins to destinations. This is how we generated our transit accessibility data for later phases of the project.
3) Amenity Weights:
    - Contains code for how amenity weights data was sourced (Google API) and how weights were computed from the web scraped data.
4) Accessibility Measures:
    - Code for converting the travel time matrix (computed in (2)) into transit accessibility measures. This also involves cleaning the measures so they include NA values where no transit routes were available since we deemed it important to show on a map where these dissemination blocks are found.
5) Visualization:
    - Contains code for rendering and outputting HTML maps from the accessibility measures (4) which could be loaded on the dashboard for final visualization.
6) Analysis:
    - Contains code used for analyzing the transit accessibility measures developed in (4).