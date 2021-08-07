# Dashboard Documentaion

This dashboard was built in R Shiny and deployed on Heroku [this link](https://vancouver.ca/images/cov/feature/skytrain-landing.jpg).

**Outline**:
    - `datatable`: directory for csv data used on our experimental tabs. Since Heroku has a 15 minute built limit, we were unable to publish the tabs for unsupervised analysis and data exploration (which depend on this data) because it would take too long to build the stack (there were simply too many libraries). In the future we plan on using Pakrat and Docker to deploy this build in a much faster way.
    - `maps`: all maps, Leaflet and Kepler, used for the dashboard's primary visualizations. Their directories are organized for app.R to call on the correct html renders.
    - `styles`: general css aesthetics used on the dashboard.
    - `www`: photos included on the dashboard.
    - `app.R`: primary code for the app. This includes both the `ui` function and the `server` function which interact in a reactive way to provide dashboard interactivity.
    - `init.R`: initialization script for installing dashboard library dependencies.
    - `run.R`: script necessary for the dashboard to run and to not timeout within 60 seconds of user inactivity.

Authors: Graham Kerford, Yuxuan Cui, Rain Shen, Luka Vukovic