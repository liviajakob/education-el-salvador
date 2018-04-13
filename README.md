# Inequality in Access to Tertiary Education – Evidence from El Salvador

## Project Description
The aim of this project is to examine how spatial and socioeconomic factors shape inequalities in access to postsecondary education in the Latin American country El Salvador. The study conducts a logistic regression analysis with multiple predictors using data from the 2015 Salvadoran household survey Encuesta de Hogares de Propósitos Múltiples (EHPM). To include spatial context the number of accessible postsecondary institutions and study programs in different time radii are calculated.

## Methods

- Calculation of number of accessible postsecondary institutions and study programs in different time radii using road network data
- Logistic Regression Model with multiple predictors – including travel time radii – using El Salvador Houshold Survey data (see Stata code here: */calculations/inequ_access2017.do*)




## Content

 – *Paper__Access_to_Education.pdf* – Academic Paper; explains data, methods and results; Author: Livia Jakob

- */calculations* - folder containing data and script for the statistical evaluation
  - *inequ_access2017.do* – Do-file for stata 
  - *traveltime.csv* – Traveltime radii to postsecondary institutions, calculated with ArcGIS. E.g. "UNI75" column reprensents how many postsecondary institutions can be reached within 75 minutes travel time. For more information see the paper.
  - *EHPM 2015.DTA.zip* – Household survey data El Salvador, 2015
  - *postsecodary_institutions.xls* – Spreadsheet containing data on every postsecondary institution in El Salvador. Data collected in January 2017
  
- */figures* – folder containing figures and diagrams
  - *school_system.pdf* – Diagram displaying the school system in El Salvador
  - *traveltime_concept.jpg* – Diagram displaying how the travel times to postsecondary schools are calculated
  - *travel-time-radii.pdf* – Calculated travel time radii using ArcMap
  - *travel-distance.pdf* – Diagram displaying travel distance to closest postsecodary institution
  - *travel_time_one_uni.pdf* – Map displaying the calculated travel time for one university
  - *road_network.jpg* – Map displaying the road network in El Salvador
  - *postsecodary_inst.jpg* – Map displaying the postsecondary institutions in El Salvador; split up into public and private institutions
  
For figures created with stata see the paper.
  

