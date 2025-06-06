## A High Performing, Scalable Model for Computing and Visualizing Public Transit Accessibility

> This codebase was a prototyped capstone project which was sourced by Statistics Canada in the implementation of [Proximity Measures Data Viewer](https://www150.statcan.gc.ca/n1/pub/71-607-x/71-607-x2020011-eng.htm). Metropolitan Vancouver and its cultural amenities were used as a proof of concept example on how to measure urban transit accessibility in terms of time and efficiency.
>
> ~[Deprecated] **Dashboard Link:**  [Vancouver Transit Accessibility to Cultural Amenities Dashboard](https://van-transit-access2.herokuapp.com/)~
>
> Since the dashboard has been shut off, you can find pre-rendered html maps within the /dashboard/maps directoty or see the [dashboard repo](README.md) for the hosted version of the app itself.
>
> All html renderings of our accessibility scores measures were developed using the [R5-Routing algorithm](https://ipeagit.github.io/r5r/) to prototype computation of transit accessibility for data driven urban planning.

**The goal of this codebase was to develop methods for answering questions such as...**

#### **...how is Vancouver's transit accessibility represented when judged by time (Isochrones)? ie. How much time is required to reach the nearest cultural amenity?**
![image](https://github.com/user-attachments/assets/ebbda2cc-00a8-4d29-81ac-e7049c980252)

![image](https://github.com/user-attachments/assets/2f27bbdc-358b-4b30-8146-38457ab17524)

#### **...how is Vancouver's transit accessibility when judged by efficiency? ie. How well does accessibility match an estimated demand?**
![image](https://github.com/user-attachments/assets/d2d3a19b-4860-4dc9-ae28-db2fd9ec12a9)


## A Case Study on Cultural and Art Amenities in Metro Vancouver

![Vancouver](https://vancouver.ca/images/cov/feature/skytrain-landing.jpg)

### **Introduction**

Transportation network analysis is fundamental to urban planning for it determines how resources are distributed across a population. Resources come in the form of amenities such as grocery stores, schools, parks, and hospitals. Our client, Statistics Canada produces data to better understand Canada’s population, resources, economy, society, and culture. They have previously developed network accessibility measures based on distance of driving, and walking to compute proximity scores for various types of amenities.

### **Problem**

Accessibility measures based on time using transit have not yet been incorporated into proximity scores due to its multi-modal complexity and computational intensity. In 2016, 22.3% of Canadians depended on public transit in large cities; thus, incorporating transit accessibility measures is paramount to not under-represent large segments of the population which can inevitably worsen pre-existing inequalities in the urban landscape. 

### **Objective**

The aim of this project was to establish a first iteration of an open source scalable framework for data collection and analysis of transit accessibility measures. We validated our framework on Vancouver, raising the question of, “How accessible are Vancouver’s cultural amenities (libraries, museums, art galleries, and theatres) using the current transit system?”

### **Methodology/Results**

To address the computational intensity of multimodal shortest path routing, we use Conveyal’s R5 realistic routing algorithm available in R as r5r. It allows us to compute over 5.3 million transit routes repeatedly, 360 times in a day over 3 days, in just a matter of one hour. The travel time matrix was then used to develop three accessibility measures: one based on time, one on scores, and one on percentiles which were visualized with Leaflet and Kepler.gl and embedded in an R shiny dashboard. 

### **Conclusion**

This project provides a high performing and scalable framework for producing three unique transit accessibility measures for network analysis using Greater Vancouver as an initial use-case scenario. The frameworks can be further developed and adopted by urban developers to ensure equitable, sustainable, and optimal urban design for years to come.

**Authors:**

*Luka Vukovic, Yuxuan Cui, Rain Shen, Graham Kerford*
