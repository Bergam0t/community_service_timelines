source('./r_files/flatten_HTML.r')

############### Library Declarations ###############
libraryRequireInstall("plotly");
libraryRequireInstall("ggplot2");
libraryRequireInstall("RColorBrewer");
libraryRequireInstall("dplyr");
libraryRequireInstall("tidyr");
libraryRequireInstall("glue");
libraryRequireInstall("lubridate");
####################################################

################### Actual code ####################

dataset <- Values %>%
    # Remove common words that clog up the display
    mutate(Label = stringr::str_replace_all(Label, "Service|Team", "") %>% stringr::str_squish() %>% trimws()) %>%
    mutate(Label = Label %>% stringr::str_replace_all(' - ', ' ')) %>%
    # mutate(EndDate = case_when(
    #     typeof(EndDate) == "character" & EndDate == "" ~ as.character(NA), 
    #     TRUE ~ EndDate
    #     )
    #     ) %>%
  # Safest to switch to rowwise for date conversion else a single failed parse can result in a full column of nulls
  rowwise() %>%
    mutate(Date = as.Date(Date, 
                          tryFormats = c("%Y-%m-%d", "%Y/%m/%d", "%d/%m/%Y"), optional=TRUE)) %>% 
  
  mutate(EndDate = case_when(is.na(EndDate) ~ as.Date(NA),
                              EndDate == "" ~ as.Date(NA),
                              TRUE ~  as.Date(EndDate, tryFormats = c("%Y-%m-%d", "%Y/%m/%d", "%Y-%M-%d", "%Y/%M/%d", "%d-%M-%Y", "%d/%M/%Y", "%d-%m-%Y", "%d/%m/%Y"), optional=TRUE)
    )
    ) %>% 
  ungroup()
  #mutate(Date = lubridate::ymd(Date),
  #       EndDate = lubridate::ymd(EndDate)
  #) 
    #   mutate(Date = lubridate::parse_date_time2(Date, orders=c("ymd", "dmy")) %>% as.Date(),
    #       EndDate = lubridate::parse_date_time2(EndDate, orders=c("ymd", "dmy")) %>% as.Date()
    #   ) 
    # mutate(Date = ymd(Date),
    #        EndDate = ymd(EndDate)
    #  ) 

if (length(unique(dataset$ClientID)) > 1) {

    # fig <- plotly::plotly_empty(type = "scatter", mode = "markers") %>%
    # plotly::config(
    #   displayModeBar = FALSE
    # ) %>%
    # plotly::layout(
    #   title = list(
    #     text = title,
    #     yref = "Please Select a Single Client",
    #     y = 0.5
    #   )
    # )

    fig <- plot_ly(type='scatter') %>%
      plotly::layout(
        title = list(
          text = title,
          yref = "Please Select a Single Client",
          y = 0.5
        )
      )

  } else {

    
  #######################################  
  # Start by plotting referrals
  ######################################
    
  # Referrals from different services can overlap, so they should be displayed on separate lines
  # However, multiple referrals to the same service should not overlap. To show patterns of repeated
  # service access, make these all visible on the same line.
    
    
  dataset_referrals <- dataset %>%
    filter(Type == "Referral")
  
  dataset_contacts <- dataset %>% 
    filter(Type == "Contact") 

  # Theoretically there shouldn't be overlapping intervals for the same team
  # So we can always put a team on the same line when it's within the same
  # overarching interval
  Y_pos_df <- dataset_referrals %>% 
    # Keep only 1 instance per team
    # Do it here so teams will be on the same line across intervals
    distinct(Label, .keep_all=TRUE) %>%
    arrange(Date, EndDate) %>% 
    mutate(Y_Pos = row_number()) %>% 
    ungroup() %>% 
    select(Label, Y_Pos)
  
  # Join back to the full data 
  dataset_referrals <- dataset_referrals %>% 
    left_join(Y_pos_df, by="Label")
  
  # Create a colour palette based on the number of distinct teams
  referral_palette <- Y_pos_df %>% distinct(Label)
  
  my_pal <- colorRampPalette(brewer.pal(n = nrow(referral_palette), "Set3"))
  
  # Now we add a colour to each ward
  referral_palette <- referral_palette %>% 
    mutate(RowNum = row_number()) %>% 
    left_join(my_pal(nrow(referral_palette)) %>% as_tibble() %>% mutate(RowNum = row_number()), by="RowNum") %>%
    rename(FillColour = value) %>%
    select(-RowNum)
  
  dataset_referrals <- dataset_referrals %>%  
    # Join to the colour palette
    left_join(referral_palette, by="Label")  %>%
    arrange(Date) %>% 
    # Take this to be 'length on caseload'
    mutate(LoC = difftime(EndDate, Date, units="days") %>% as.numeric()) %>%
    # Add in a label for the length of stay
    # When we don't have an end date, calculate it up to today
    # Format the label differently depending on total length 
    # (switch from days to years + months)
  mutate(LoCToDate = case_when(
    EndDate < lubridate::today() ~ LoC,
    TRUE ~ difftime(tidyr::replace_na(EndDate, Sys.Date()), Date, units='days') %>% as.numeric()
  )) %>% 
    mutate(Months = case_when(
      LoCToDate > 364 ~ (lubridate::as.period(LoCToDate, unit='days') %>% lubridate::time_length(unit='months') - ((lubridate::as.period(LoCToDate, unit='days') %>% lubridate::time_length(unit='years') %>% floor())*12)) %>% floor(),
      TRUE ~ 0
    ),
    Years = case_when(
      LoCToDate > 364 ~ (lubridate::as.period(LoCToDate, unit='days') %>% lubridate::time_length(unit='years')) %>% floor(),
                         TRUE ~ 0),
    Months = case_when(
      Months == 1 ~ glue::glue("{Months} month"),
      TRUE ~ glue::glue("{Months} months")
    ),
    Years = case_when(
      Years == 1 ~ glue::glue("{Years} year"),
      TRUE ~ glue::glue("{Years} years")
    )
    ) %>% 
    mutate(LoCConverted = case_when(
      # LoCToDate > 364 ~ lubridate::as.period(LoCToDate, unit="days") %>% lubridate::time_length(unit="years") %>% round(1),
      LoCToDate > 364 ~ glue("{Years} {Months}"),
      TRUE ~ glue("{LoCToDate}")
    )) %>% 
    mutate(LoCToDateLabels = case_when(
      EndDate < lubridate::today() & LoCToDate < 30 ~ glue::glue("{LoCConverted} d"),
      EndDate < lubridate::today() & LoCToDate < 365 ~ glue::glue("{LoCConverted} days"),
      ((EndDate < lubridate::today()) & (LoCToDate > 364)) ~ glue::glue("{LoCConverted}"),
      ((EndDate != lubridate::today()) & (LoCToDate > 364)) ~ glue::glue("{LoCConverted} (ONGOING)"),
      TRUE ~ glue::glue("{LoCConverted} days (ONGOING)"))
    ) %>% 
    # Finalise the label to show both ward and LoS (plus indication of whether stay is still in progress)
    mutate(
      # The longer the length of the referral, the wider we can make the label
      # This should minimise overlap of labels
      # But bear in mind this may look different at different levels of zoom
      TeamLabelWithLoC = case_when( 
        
        LoCToDate < 100  ~ glue::glue(
          "<b>{Label %>% stringr::str_wrap(10)}</b>\n{LoCToDateLabels}
          "),
        # Doing like this (as opposed to wrapping the whole thing and then forcing a newline
        # after the team label) prevents you from ending up with just a small part of the length
        # of time being on a line by itself
        
        Years < 1  ~ glue::glue(
          "<b>{Label %>% stringr::str_wrap(20)}</b> {LoCToDateLabels %>% stringr::str_wrap(20)}"
        )
        %>% 
          stringr::str_replace_all("</b> ", "</b>\n"),
        
        Years < 2  ~ glue::glue(
          "<b>{Label %>% stringr::str_wrap(40)}</b> {LoCToDateLabels %>% stringr::str_wrap(40)}"
          )
         %>% 
        stringr::str_replace_all("</b> ", "</b>\n"),
        
        Years < 3 ~ glue::glue(
          "<b>{Label %>% stringr::str_wrap(60)}</b> {LoCToDateLabels %>% stringr::str_wrap(60)}"
        )
        %>% stringr::str_replace_all("</b> ", "</b>\n"),
        
        TRUE ~ glue::glue(
          "<b>{Label %>% stringr::str_wrap(80)}</b> {LoCToDateLabels %>% stringr::str_wrap(80)}"
        )
        %>% stringr::str_replace_all("</b> ", "</b>\n")
        
    )
    ) %>%
    # To make current stay display correctly we need to replace the NA end date with the current date
    mutate(EndDate = tidyr::replace_na(EndDate, Sys.Date())) %>%
    # We want to place the labels in the middle of each stay - work out 
    # the midpoint between admission and discharge
    # Sate midpoint code modified from https://stat.ethz.ch/pipermail/r-help/2013-November/363276.html
    mutate(IntermediatePoint = Date + floor((EndDate-Date)/2)) 
  
  # Calculate the first referral that falls within each contact
  referral_first_contact <- dataset_referrals %>%
    mutate(ReferralNumber = row_number()) %>% 
    left_join(dataset_contacts %>% select(Label, Date) %>% rename(ContactDate = Date), by="Label") %>% 
    filter(ContactDate >= Date) %>% 
    filter(ContactDate <= EndDate | is.na(EndDate) & !is.na(ContactDate)) %>% 
    group_by(ReferralNumber) %>% 
    arrange(ContactDate) %>% 
    distinct(ReferralNumber, .keep_all=TRUE) %>% 
    ungroup()
  
  
  
  # Reshape the client df to a long format for plotting
  plot_df <- dataset_referrals %>% 
    select(ClientID, Label, Date, EndDate, Y_Pos) %>% 
    left_join(referral_first_contact %>% select(Label, Date, ContactDate) %>% rename(FirstContact=ContactDate)) %>% 
    # mutate(Wait = case_when(is.na(AppointmentDate) ~ "N/A", 
    #           TRUE ~ difftime(AppointmentDate, ReferralDate, unit="days") %>% as.character() %>% paste("days"))) %>%
    tidyr::gather(key="name", value="value", Date, EndDate)
  
  # Generate the base plotly figure
  # This just puts invisible points but they are important for setting up the axes
  # and giving the hover text points to anchor to
  fig <- plot_df %>%
    plot_ly(x=~value, 
            y=~Y_Pos+0.5, 
            alpha=0,
            text = ~paste0('</br>Team: ', Label,
                           # If discharge date is today we know that means they're actually still in
                           # so just display 'ongoing'
                           # Whereas if it's any other date then it must be a concluded stay
                           '</br>', name,  ': ', case_when(value >= lubridate::today() ~ "Ongoing", 
                                                           TRUE ~ format(value, "%d %b %Y"))
                           ,
                           
                           '</br>First Appointment In Referral: ', case_when(is.na(FirstContact) ~ "None",
                                                           TRUE ~ format(FirstContact, "%d %b %Y")) #,
                          #  
                          #  '</br>Wait: ', Wait,
                          #                                  
                          #  '</br>Referral Urgency: ', case_when(is.na(ReferralUrgency) ~ "None", 
                          #                                                    TRUE ~ ReferralUrgency),
                          #  
                          #  
                          # case_when(is.na(ReferralReason) ~ "", TRUE ~ paste0( '</br>Referral Reason: ', ReferralReason)),
                          #  
                          # case_when(is.na(DischargeReason) ~ "", TRUE ~ paste0( '</br>Discharge Reason: ', DischargeReason))
                           ),
            hoverinfo = 'text',
            type='scatter',
            mode="lines",
            width = NULL, 
            height = NULL
    )
  
  # Add shapes to the layout
  # These will be rectangles showing stays
  
  i <- 1
  shapes <- list()
  points <- list()
  
  # Iterate through and generate one rectangle per stay
  while (i < nrow(dataset_referrals) + 1) {
    # print(i)
    
    shapes[[i]] <- list(type = "rect",
                        fillcolor = dataset_referrals[i,]$FillColour, 
                        opacity = 0.6,
                        x0 = dataset_referrals[i,]$Date, 
                        x1 = dataset_referrals[i,]$EndDate, 
                        xref = "x",
                        # Add so that there's a slight gap between each row
                        y0 = dataset_referrals[i,]$Y_Pos + 0.1, 
                        y1 = dataset_referrals[i,]$Y_Pos + 0.9, 
                        yref = "y"
    )

    
    
    
    
    
    i <- i+1
    
  }
  
  
  ## Add in a box to show the time to the first contact in the referral
  
  k <- 1
  
  # Iterate through and generate one rectangle per stay
  while (k < nrow(dataset_referrals) + 1) {
    
    # First, find the first contact in a referral period that falls within the referral
    
    if (!is.na(referral_first_contact[k,]$ContactDate)) {
      
      shapes[[i]] <- list(type = "rect",
                          fillcolor = "#A9AAAA", 
                          # line = list(color = rgb(170, 170, 170), 
                          #             dash= rgb(170, 170, 170), 
                          #             opacity= client_referral_data_final[i,]$IsTeamOfInterestLineOpacity), 
                          opacity = 0.5,
                          x0 = referral_first_contact[k,]$Date, 
                          x1 = referral_first_contact[k,]$ContactDate, 
                          xref = "x",
                          # Add so that there's a slight gap between each row
                          y0 = referral_first_contact[k,]$Y_Pos + 0.1, 
                          y1 = referral_first_contact[k,]$Y_Pos + 0.9, 
                          yref = "y"
      )
      
      i <- i+1
      
    }
    
    k <- k+1
    
  }
  
  
  # Add team labels 
  fig <- fig %>% 
    add_annotations(
      x = dataset_referrals$IntermediatePoint,
      y = dataset_referrals$Y_Pos + 0.5,
      text = dataset_referrals$TeamLabelWithLoC,
      xref = "x",
      yref = "y",
      showarrow = FALSE,
      bgcolor="#ffffff",
      opacity=0.6,
      font = list(size=9)
      ) 
  
  
  
  
  ###########################################
  # Add in boxes indicating inpatient stays
  ###########################################
  #These should not overlap, so can be boxes on a single line.
  
  dataset_wardstay <- dataset %>% 
    filter(Type == "Inpatient")
  
  ## Add in a box to show the time to the first contact in the referral
  
  if (nrow(dataset_wardstay > 0)) {
  
  i <- i+1
  m <- 1
  
  # Iterate through and generate one rectangle per stay
  while (m < nrow(dataset_wardstay) + 1) {
    
      shapes[[i]] <- list(type = "rect",
                          fillcolor = "#808080", 
                           line = list(
                             #color = rgb(170, 170, 170), 
                                       dash= "dash" 
                          #             opacity= client_referral_data_final[i,]$IsTeamOfInterestLineOpacity
                          ), 
                          opacity = 0.3,
                          x0 = dataset_wardstay[m,]$Date, 
                          x1 = dataset_wardstay[m,]$EndDate, 
                          xref = "x",
                          # Add so that there's a slight gap between each row
                          y0 = max(dataset_referrals$Y_Pos) + 1 + 0.1, 
                          y1 = max(dataset_referrals$Y_Pos) + 1 + 0.9, 
                          yref = "y"
      )
      
      
      
      
      m <- m+1
      
      i <- i+1
  
  
  }
  
  
  fig <- fig %>%
    add_trace(x= dataset_wardstay$Date,
              y =  max(dataset_referrals$Y_Pos) + 1.2 ,
              text=paste0(
                "Inpatient Admission: ", dataset_wardstay$Date %>% format('%d %b %Y') %>% paste(dataset_wardstay$Label, .)
              ),
              hovertext="",
              type="scatter",
              mode="markers",
              showlegend=FALSE,
              #hovermode='none',
              marker = list(
                color = 'rgb(218, 41, 28)',
                opacity=0,
                alpha=0,
                size = 10
              )
    )
  
  fig <- fig %>%
    add_trace(x= dataset_wardstay$EndDate,
              y =  max(dataset_referrals$Y_Pos) + 1.8 ,
              text=paste0(
                "Inpatient Discharge: ", dataset_wardstay$EndDate %>% format('%d %b %Y') %>% paste(dataset_wardstay$Label, .)
              ),
              hovertext="",
              type="scatter",
              mode="markers",
              showlegend=FALSE,
              #hovermode='none',
              marker = list(
                color = 'rgb(218, 41, 28)',
                opacity=0,
                alpha=0,
                size = 10
              )
    )
  
  
  # Add label indicating these are inpatient stays
  
  fig <- fig %>% 
    add_annotations(
      x = Sys.Date(),
      y = max(dataset_referrals$Y_Pos) + 1.5,
      text = "Inpatient\nStays",
      xref = "x",
      yref = "y",
      showarrow = FALSE,
      bgcolor="#ffffff",
      opacity=0.6,
      font = list(size=9)
    )
  
  }
  
  ####################################################################################
  # Add in additional point types for services which are accessed without a referral
  ####################################################################################
  
  dataset_unscheduled_contacts <- dataset %>% 
    filter(Type != "Referral" & Type != "Contact" & Type != "Inpatient")
  
  # Get the number of different types of unscheduled contact - they will each be displayed on a separate line
  types_unscheduled_contact <- dataset_unscheduled_contacts %>% distinct(Type)
  
  if (nrow(types_unscheduled_contact) >= 1) {
  
  for (contact_type_n in 1:nrow(types_unscheduled_contact)) {
    
    what_contact_type <- (types_unscheduled_contact %>% pull())[contact_type_n]
    
    dataset_unscheduled_contacts_single_type <- dataset_unscheduled_contacts %>% 
      filter(Type == what_contact_type)
    
    
    fig <- fig %>%
      add_trace(x= dataset_unscheduled_contacts_single_type$Date,
                y = max(dataset_referrals$Y_Pos) + contact_type_n + 1.5,
                text=paste0(
                  dataset_unscheduled_contacts_single_type$Date %>% format('%d %b %Y') %>% paste(dataset_unscheduled_contacts_single_type$Label, .)
                  ),
                hovertext="",
                type="scatter",
                mode="markers",
                showlegend=FALSE,
                #hovermode='none',
                marker = list(
                  color = 'rgb(218, 41, 28)',
                  opacity=0.3,
                  size = 10,
                  line = list(
                    color = 'rgb(255, 255, 255)',
                    width = 2
                  )
                )
                )
            }
  }
  
  #####################################################
  # Add in individual contacts relating to referrals
  #####################################################

   dataset_contacts <- dataset %>% 
    left_join(dataset_referrals %>% select(Label, Y_Pos),
              by="Label")

  if (nrow(dataset_contacts) >= 1) {
    
    fig <- fig %>%
      add_trace(x= dataset_contacts$Date,
                y = dataset_contacts$Y_Pos + 0.2,
                text=paste0(
                  dataset_contacts$Label %>% paste("Team:", .),
                  "<br>",
                  dataset_contacts$Date %>% format('%d %b %Y') %>% paste("Contact Date:", .)
                ),
                hovertext="",
                type="scatter",
                mode="markers",
                showlegend=FALSE,
                #hovermode='none',
                marker = list(
                  color = 'rgb(170, 170, 170)',
                  opacity=1,
                  size = 10,
                  line = list(
                    color = 'rgb(255, 255, 255)',
                    width = 2
                  )
                )
      )
  }

  ###################################
  # Add finishing touches
  ###################################
  
  fig <- layout(fig, 
                shapes = shapes,
                # hovermode='x unified',
                hovermode='closest',
                # title=glue::glue(),
                title = list(
                  text = paste0(
                    glue::glue('Client: {unique(dataset$ClientID)}')
                  )),
                
                
                xaxis = list(
                  # Set default to just display last 5 years
                  autorange = FALSE,
                  range = c(as.character(lubridate::today() - lubridate::years(5)), 
                            as.character(lubridate::today() + lubridate::days(31))
                  ),
                  title=FALSE,
                  # Add several buttons that will jump to plot to predefined
                  # time periods
                  rangeselector = list(
                    
                    buttons = list(
                      # list(
                      #   count = 3,
                      #   label = "3 mo",
                      #   step = "month",
                      #   stepmode = "backward"),
                      list(
                        count = 6,
                        label = "6 mo",
                        step = "month",
                        stepmode = "backward"),
                      list(
                        count = 1,
                        label = "1 yr",
                        step = "year",
                        stepmode = "backward"),
                      list(
                        count = 2,
                        label = "2 yr",
                        step = "year",
                        stepmode = "backward"),
                      list(
                        count = 3,
                        label = "3 yr",
                        step = "year",
                        stepmode = "backward"),
                      list(
                        count = 5,
                        label = "5 yr",
                        step = "year",
                        stepmode = "backward"),
                      list(
                        count = 10,
                        label = "10 yr",
                        step = "year",
                        stepmode = "backward"),
                      # list(
                      #   count = 1,
                      #   label = "YTD",
                      #   step = "year",
                      #   stepmode = "todate"),
                      list(step = "all"))),
                  
                  rangeslider = list(
                    type = "date",
                    thickness = 0.05,
                    showgrid = TRUE
                    
                  )),
                
                yaxis = list(
                  # Set default to just display last 2 years
                  autorange = FALSE,
                  # autorange = TRUE,
                  range = c(1, dataset_referrals %>% select(Y_Pos) %>% max() + 4),
                  # Hide axis labels as they have no meaning for the graph
                  showticklabels = FALSE,
                  title=FALSE
                )
                
  ) 
  }

    p <- fig

####################################################

############# Create and save widget ###############
internalSaveWidget(p, 'out.html');
####################################################

################ Reduce paddings ###################
ReadFullFileReplaceString('out.html', 'out.html', ',"padding":[0-9]*,', ',"padding":0,')
####################################################
