#' NOTE: the source URLs below are no longer available (HTTP 410), so this
#' script cannot be re-run. The shipped data was later patched by
#' data-raw/ef_europe_emep_db_fix_110.R (FC rows stored as MJ/km, #110).
#'
#' REPORT
#'
#' There are four main steps in this script
#'
#' 1) Load Libraries and internal functions
#' 2) EMEP2019 data prep
#' 3) EMEP2016 data prep
#' 4) EMEP2013 data prep
#' 5) EMEP2007 data prep
#' 6) Overlap between EMEP2007 and EMEP2013
#' 7) Check how CO2 actually behaves
#' 8) Rbindlist all EF and export
#'
#'
#' Source: EMEP/EEA air pollutant emission inventory guidebook 2019
#    1.A.3.b.i, 1.A.3.b.ii, 1.A.3.b.iii, 1.A.3.b.iv
#    Passenger cars, light commercial trucks, heavy-duty vehicles including
#    buses and motor cycles
#
# Author: Joao Bazzo (joao.bazzo@gmail.com)

#### LOAD LIBRARIES----
#rm(list=ls())
library(magrittr)
library(data.table)
library(openxlsx)
`%nin%` = Negate(`%in%`)
`%nlike%` = Negate(`%like%`)

###### EMEP 2019 ----
# read file
body <- "https://www.eea.europa.eu/publications/"
link2019 <- paste0(body,"emep-eea-guidebook-2019/part-b-sectoral-guidance-chapters/1-energy/1-a-combustion/road-transport-appendix-4-emission/at_download/file")
emep2019_raw <- openxlsx::read.xlsx(link2019,sheet = 2) %>% data.table::setDT()
emep2019 <- data.table::copy(emep2019_raw)

# overview 'Category' names
names(emep2019)
emep2019[,.N,by = .(Category,Fuel,Segment,Euro.Standard,Technology,Pollutant)][N>1,]
emep2019$Category %>% unique()
emep2019$Pollutant %>% unique()

# only buses
emep2019 <- emep2019[Category %in% "Buses",] 

# simplify 'Fuel' names
# hydrid vehicle (HV)
# plug-in hybrid vehicle (PHEV)
# electric vehicle with range-extender (EREV)
# batery electric vehicle (BEV)
emep2019$Fuel %>% unique()
emep2019[Fuel %in% "Diesel", Fuel := "D"]
emep2019[Fuel %in% "Diesel Hybrid ~ Diesel", Fuel := "DHD"]
emep2019[Fuel %in% "Diesel Hybrid ~ Electricity", Fuel := "DHE"]
emep2019[Fuel %in% "CNG", Fuel := "CNG"]
emep2019[Fuel %in% "Biodiesel", Fuel := "BD"]

# simplify 'Segment'
unique(emep2019$Segment)
emep2019[,Segment := stringr::str_replace_all(Segment,"Articulated","Artic")]
emep2019[,Segment := stringr::str_replace_all(Segment,"Urban Buses","Ubus")]
emep2019[,Segment := stringr::str_replace_all(Segment,"Standard","Std")]
emep2019[,Segment := stringr::str_replace_all(Segment,"Urban Biodiesel Buses","Ubus Std 15 - 18 t")]
emep2019[,Segment := stringr::str_replace_all(Segment,"Urban CNG Buses","Ubus Std 15 - 18 t")]
emep2019[,Segment := stringr::str_replace_all(Segment,"Ubus Diesel Hybrid","Ubus Std 15 - 18 t")]
unique(emep2019$Segment)

# simplify "Euro.Standard"
data.table::setnames(emep2019,"Euro.Standard","Euro")
unique(emep2019$Euro)
emep2019[Euro %like% "Euro 6" | Euro %like% "Euro VI", Euro := "VI"]
emep2019[Euro %in% "Euro 5" | Euro %in% "Euro V", Euro := "V"]
emep2019[Euro %in% "Euro 4" | Euro %in% "Euro IV", Euro := "IV"]
emep2019[Euro %in% "Euro 3" | Euro %in% "Euro III", Euro := "III"]
emep2019[Euro %in% "Euro 2" | Euro %in% "Euro II", Euro := "II"]
emep2019[Euro %in% "Euro 1" | Euro %in% "Euro I", Euro := "I"]
unique(emep2019$Euro)

# simplify 'Units' names
# emep2019[Pollutant %like% "g/Kwh",units := "g/Kwh"]
# emep2019[Pollutant %like% "#/Kwh",units := "#/Kwh"]
# emep2019[is.na(units),units := "g/km"]

# simplify 'Pollutant' names
unique(emep2019$Pollutant)
data.table::setnames(emep2019,"Pollutant","Pol")
emep2019[Pol %in% "PM Exhaust",Pol := "PM10"]
emep2019[Pol %in% "PM Exhaust [g/kWh]",Pol := "PM10"]
unique(emep2019$Pol)

# remove PM10 Euro VI and V (there are better data on EMEP2016)
emep2019 <- emep2019[!(Pol == "PM10" & Euro %in% c("V","VI")),]
# adjust "Mode"
unique(emep2019$Mode)
emep2019[Mode %in% "", Mode := NA]

# simplify Technology
unique(emep2019$Technology)
emep2019[Technology %in% "", Technology := "-"]
emep2019[is.na(Technology), Technology := "-"]
unique(emep2019$Technology)

# reduction factor
unique(emep2019$`Reduction.Factor.[%]`)
data.table::setnames(emep2019,"Reduction.Factor.[%]","RF")

# exclude extra columns
emep2019[1]
emep2019[,`:=`(`50` = NULL,`Bio.Reduction.Factor.[%]` = NULL,
               `EF.[g/km].or.ECF.[MJ/km].or.#/km.or.#/kWh.or.g/kWh` = NULL,
               `X23` = NULL)]

# simplify Load
unique(emep2019$Load)
emep2019[is.na(Load)]
emep2019[is.na(Load), Load := 0.5]
unique(emep2019$Load)

# simplify Road.Slope
unique(emep2019$Road.Slope)
data.table::setnames(emep2019,"Road.Slope","Slope")
emep2019[is.na(Slope), Slope := 0.0]
unique(emep2019$Slope)

# add Function
emep2019[,Function := "(Alpha*Speed^2+Beta*Speed+Gamma+Delta/Speed)/(Epsilon*Speed^2+Zita*Speed+Hta)*(1-rf)*k"]
emep2019[,Function_ID := "2019_1"]
emep2019[,k := 1]
emep2019[,Thita := 0]

# simplify speed
emep2019[1]
data.table::setnames(emep2019,"Max.Speed.[km/h]","Vmax")
data.table::setnames(emep2019,"Min.Speed.[km/h]","Vmin")
emep2019[1]

# avoid duplicated EF
ColNames <- c("Category","Fuel","Segment","Euro","Technology","Pol","Slope","Load","Vmin","Vmax")
emep2019 <- emep2019[,.SD[1],by = ColNames]

# avoid duplicated EF, with only change on 'Mode' character
ColNames <- c("Category","Fuel","Segment","Euro","Technology","Pol","Slope","Load","Vmin","Vmax",
              "Alpha","Beta","Gamma","Delta","Epsilon","Zita","Hta","RF","Function","Function_ID","k","Thita")
emep2019 <- emep2019[,.SD[1],by = ColNames]

# remove "Mode"
emep2019[,Mode := NULL]


#emep2019[Pol == "PM10" & Segment %like% "Artic",.SD[1],by = Euro]

##### EMEP 2016 ---------
#
#


# download and read file
body <- "https://www.eea.europa.eu/publications/"
link2016 <- paste0(body,"emep-eea-guidebook-2016/part-b-sectoral-guidance-chapters/1-energy/1-a-combustion/1-a-3-b-i-1/at_download/file")
a <- tempdir()
download.file(link2016,destfile = paste0(a,"2016ef.xlsx"))
emep2016_raw <- openxlsx::read.xlsx(xlsxFile = paste0(a,"2016ef.xlsx"), sheet = 1) %>% data.table::setDT() 
emep2016 <- data.table::copy(emep2016_raw)

# simplify by 'Pollutant' and 'Category"
unique(emep2016$Category)
emep2016 <- list(emep2016[Pollutant %in% "FC" & Category %in% "Buses",],
                 emep2016[Pollutant %in% "PM Exhaust" & Category %in% "Buses"
                          & Euro.Standard %in% c("Euro V","Euro VI"),])
emep2016 <- data.table::rbindlist(emep2016)
names(emep2016)

# simplify 'Pollutant' <-> 'Pol'
emep2016$Pollutant %>% unique()
data.table::setnames(emep2016,"Pollutant","Pol")
emep2016[Pol %in% "PM Exhaust", Pol := "PM10"]
emep2016$Pol %>% unique()

# simplify 'Subsector' <-> 'Segment'
unique(emep2016$Segment)
emep2016[,Segment := stringr::str_replace_all(Segment,"Articulated","Artic")]
emep2016[,Segment := stringr::str_replace_all(Segment,"Urban Buses","Ubus")]
emep2016[,Segment := stringr::str_replace_all(Segment,"Standard","Std")]
emep2016[,Segment := stringr::str_replace_all(Segment,"Urban Biodiesel Buses","Ubus Std 15 - 18 t")]
emep2016[,Segment := stringr::str_replace_all(Segment,"Urban CNG Buses","Ubus Std 15 - 18 t")]
emep2016[,Segment := stringr::str_replace_all(Segment,"Ubus Diesel Hybrid","Ubus Std 15 - 18 t")]
unique(emep2016$Segment)

# simplify by fuel
emep2016$Fuel %>% unique()
emep2016[Fuel %in% "CNG",]
emep2016[Fuel %in% "Diesel", Fuel := "D"]
emep2016[Fuel %in% "Biodiesel", Fuel := "BD"]
emep2016$Fuel %>% unique()

# simplify Road.Slope
emep2016$Road.Slope %>% unique()
data.table::setnames(emep2016,"Road.Slope","Slope")
emep2016[is.na(Slope),Slope := 0]
emep2016$Slope %>% unique()

# simplify Euro
data.table::setnames(emep2016,"Euro.Standard","Euro")
unique(emep2016$Euro)
emep2016[Euro %like% "Euro 6" | Euro %like% "Euro VI", Euro := "VI"]
emep2016[Euro %in%   "Euro 5" | Euro %in% "Euro V", Euro := "V"]
emep2016[Euro %in%   "Euro 4" | Euro %in% "Euro IV", Euro := "IV"]
emep2016[Euro %in%   "Euro 3" | Euro %in% "Euro III", Euro := "III"]
emep2016[Euro %in%   "Euro 2" | Euro %in% "Euro II", Euro := "II"]
emep2016[Euro %in%   "Euro 1" | Euro %in% "Euro I", Euro := "I"]
unique(emep2016$Euro)

# Simplify Speed
data.table::setnames(emep2016,c("Min.Speed.[km/h]","Max.Speed.[km/h]"),c("Vmin","Vmax"))
emep2016$Vmin %>% unique()
emep2016$Vmax %>% unique()

# Simplify names
names(emep2016)
data.table::setnames(emep2016,"Reduction.Factor.[%]","RF")
data.table::setnames(emep2016,"EF.[g/km].or.ECF.[MJ/km]","EF")

# add function column
emep2016[,Function := "(Alpha*Speed^2+Beta*Speed+Gamma+Delta/Speed)/(Epsilon*Speed^2+Zita*Speed+Hta)*(1-rf)*k"]
emep2016[,Function_ID := "2019_1"]

# simplify "Mode"
emep2016$Mode %>% unique()

# simplify others
names(emep2016)
emep2016[,`:=`(`120` = NULL,k = 1,`Bio.Reduction.Factor.[%]` = NULL,EF = NULL)]

# avoid duplicated EF, with only change on 'Mode' character
ColNames <- c("Category","Fuel","Segment","Euro","Technology","Pol","Slope","Load","Vmin","Vmax",
              "Alpha","Beta","Gamma","Delta","Epsilon","Zita","Hta","RF","Function","Function_ID","k","Thita")

# to understand why it happens check
#
# > emep2016[,.N,by = ColNames][N>1]
#
# it shows to there are 3 categories of CNG buses there are duplicated, with the same EF#
emep2016 <- emep2016[,.SD[1],by = ColNames]
emep2016[,Mode := NULL]

# fix Load info
emep2016[is.na(Load),Load := 0.5]
emep2016[is.na(Technology),Technology := "-"]

# add CO2
# rhc = 1.86 and roc = 0.0
co2_2016 <- data.table::copy(emep2016)[Pol == "FC" & Fuel == "CNG",][,Pol := "CO2"]
co2_2016[,k := 44.011 / (12.001 + 1.008 * 1.86  + 16 * 0 ) ]

# rbind emep2016
emep2016_final <- data.table::rbindlist(l = list(emep2016,co2_2016))


#
### EMEP 2013 ----------------------
#



# download and read file
body <- "https://www.eea.europa.eu/publications/"
link2013 <- paste0(body,"emep-eea-guidebook-2013/part-b-sectoral-guidance-chapters/1-energy/1-a-combustion/1-a-3-b-road-transport-annex-hdv-files.zip/at_download/file")
dir.create(path = paste0("test_joao/2013ef/"))
download.file(link2013,destfile = paste0("test_joao/2013ef/2013ef.zip"))
unzip(zipfile = paste0("test_joao/2013ef/2013ef.zip"),exdir = "test_joao/2013ef/")
list.files(path = paste0("test_joao/2013ef"))

# read and clean formula data
filepath2013 <- "test_joao/2013ef/1.A.3.b.i-iv Exhaust emissions from road transport data annex Sept2014 update.xlsx"
openxlsx::getSheetNames(filepath2013)

bus_eq <- openxlsx::read.xlsx(filepath2013,sheet = "HDV - BUS Equations") %>% 
  data.table::as.data.table()
colnames(bus_eq) <- c("eq_num","eq_formula")
bus_eq[,eq_num := gsub("Equation ","",eq_num)]
bus_eq[1:5]

# read EF data
emep2013_raw <- openxlsx::read.xlsx(filepath2013,sheet = "HDVs - BUS") %>% 
  data.table::as.data.table()
emep2013 <- data.table::copy(emep2013_raw)

# simplify by 'Pollutant' and 'Category"
unique(emep2013$Pollutant)
unique(emep2013$Sector)
data.table::setnames(emep2013,"Pollutant","Pol")
data.table::setnames(emep2013,"Sector","Category")
emep2013 <- emep2013[Pol %in% "FC" & Category %in% "Buses",]

# simplify 'Subsector' <-> 'Segment'
unique(emep2013$`Sub-Sector`)
data.table::setnames(emep2013,'Sub-Sector',"Segment")
emep2013[Segment == "Urban Buses Standard 15 - 18 t",Segment := "Ubus Std 15 - 18 t"]
emep2013[Segment == "Urban Buses Midi <=15 t",Segment := "Ubus Midi <=15 t"]
emep2013[Segment == "Urban Buses Articulated >18 t",Segment := "Ubus Artic >18 t"]
emep2013[Segment == "Coaches Standard <=18 t",Segment := "Coaches Std <=18 t"]
emep2013[Segment == "Coaches Articulated >18 t" ,Segment := "Coaches Artic >18 t"]
unique(emep2013$Segment)

# simplify by fuel
emep2013[, Fuel := "D"]

# simplify Euro
emep2013$Euro.No. %>% unique()
data.table::setnames(emep2013,"Euro.No.","Euro")
emep2013[,Euro := as.character(Euro)]
emep2013[Euro == "6", Euro := "VI"]
emep2013[Euro == "5", Euro := "V"]
emep2013$Euro %>% unique()

# simplify Technology
emep2013$Technology %>% unique()
emep2013[Technology %like% "EGR",Technology := "EGR"]
emep2013[Technology %like% "SCR",Technology := "SCR"]
emep2013[Technology %like% "Euro VI",Technology := "SCR"]
emep2013[is.na(Technology),Technology := "-"]

# simplify Load
emep2013$Load %>% unique()
emep2013[Load == 50,Load := 0.5]
emep2013[Load == 100,Load := 1]

# Simplify names
names(emep2013)

# add function column
data.table::setnames(emep2013,"Equation","Function_ID")
emep2013[,Function_ID := gsub("Equation ","2013_",Function_ID)]
unique(emep2013$Function_ID)

# simplify others
names(emep2013)
emep2013[,`:=`(`50` = NULL,R2 = NULL,EF = NULL)]

# create a column for 'k' parameter
emep2013[,k := 1]

# rename few columns
data.table::setnames(emep2013,"Ita","Hta")
data.table::setnames(emep2013,"Formula","Function")

# check names (comparing with emep2016 and emep2019)
emep2019 %>% names() %>% sort()
emep2016 %>% names() %>% sort()
emep2013 %>% names() %>% sort()

# add CO2
# rhc = 1.86 and roc = 0.0
co2_2013 <- data.table::copy(emep2013)[,Pol := "CO2"]
co2_2013[,k := 44.011 / (12.001 + 1.008 * 1.86  + 16 * 0 ) ]

# rbind emep2013
emep2013_final <- data.table::rbindlist(l = list(emep2013,co2_2013))




#### EMEP 2007--------------
# add analysis


## download file
link2007 <- "https://www.eea.europa.eu/publications/EMEPCORINAIR5/HDV_functions_Excel_files.zip/at_download/file"
a <- tempdir()
zipfile2007 <- paste0(a,"/HDV_functions_Excel_files.zip")
download.file(url = link2007,destfile = zipfile2007)
unzip(zipfile = zipfile2007, exdir = a)

# read files
filepath2007 <- list.files(a,pattern = "EFs",full.names = TRUE)

# read all files and rbindlist
emep2007_raw <- lapply(filepath2007,function(i){ # i = filepath2007[1]
  tmp_xls <- readxl::read_xls(i,sheet = "FC") %>% as.data.frame()
}) %>% data.table::rbindlist() #%>% data.table::setDT()
emep2007 <- data.table::copy(emep2007_raw)

# simplify by 'Pollutant' and 'Category"
unique(emep2007$Pollutant)
data.table::setnames(emep2007,"Pollutant","Pol")

# simplity 'Subsector' 
unique(emep2007$Subsegment)
data.table::setnames(emep2007,"Subsegment","Segment")
emep2007 <- emep2007[Segment %like% "Coach" | Segment %like% "Ubus"]

# get 'Euro' phases
unique(emep2007$Segment)
emep2007[Segment %like% "Euro-1",Euro := "I"]
emep2007[Segment %like% "Euro-2",Euro := "II"]
emep2007[Segment %like% "Euro-3",Euro := "III"]
emep2007[Segment %like% "Euro-4",Euro := "IV"]
emep2007[Segment %like% "Euro-5",Euro := "V"]
emep2007[Segment %like% "80ties",Euro := "PRE"] 

# update 'Segment'
emep2007[Segment %like% "Ubus Std >15-18t", Segment := "Ubus Std 15 - 18 t"]
emep2007[Segment %like% "Ubus Midi <=15t", Segment := "Ubus Midi <=15 t"]
emep2007[Segment %like% "Ubus Artic >18t", Segment := "Ubus Artic >18 t"]
emep2007[Segment %like% "Coach Std <=18t", Segment := "Coaches Std <=18 t"]
emep2007[Segment %like% "Coach 3-Axes >18t", Segment := "Coaches Artic >18 t"]

# simplify by fuel
emep2007[, Fuel := "D"]

# simplify Technology
emep2007[1]
emep2007[,Technology := "-"]

# simplify 'Load'
data.table:::setnames(emep2007,'Load (%)',"Load")
emep2007$Load %>% unique()

# simplify 'Gradient'
data.table::setnames(emep2007,'Gradient (%)','Slope')
unique(emep2007$Slope)

# simplify 'Formula' parameters
emep2007[,`:=`(`...6` = NULL,`...8` = NULL,`...14` = NULL)]
data.table::setnames(emep2007,'Formula (y: g/km; x: km/h)','Function')

data.table::setnames(emep2007,"a","Alpha")
data.table::setnames(emep2007,"b","Beta")
data.table::setnames(emep2007,"c","Gamma")
data.table::setnames(emep2007,"d","Delta")
data.table::setnames(emep2007,"e","Epsilon")

# add extra parameters such as 'Zita','Hta','Thita'
emep2007[,`:=`(Zita = 0, Hta = 0, Thita = 0)]

# Replace NA by 0, and all parameters as numeric
vector_pars <- c("Alpha","Beta","Gamma","Delta","Epsilon","Zita","Hta","Thita")
function_na <- function(i){ifelse(is.na(i),0,as.numeric(i))}
emep2007[,(vector_pars) := lapply(.SD,function_na), .SDcols = vector_pars]

# change a little bit the functions expression
unique(emep2007$Function)

emep2007[Function == "y=((e+(a*exp(((-1)*b)*x)))+(c*exp(((-1)*d)*x)))",
         Function := "((Epsilon+(Alpha*exp(((-1)*Beta)*Speed)))+(Gamma*exp(((-1)*Delta)*Speed)))"]

emep2007[Function == "y=((a*(b^x))*(x^c))",
         Function := "((Alpha*(Beta^Speed))*(Speed^Gamma))"]

emep2007[Function == "y=((a*(x^b))+(c*(x^d)))",
         Function := "((Alpha*(Speed^Beta))+(Gamma*(Speed^Delta)))"] 

emep2007[Function == "y=(a+(b/(1+exp((((-1)*c)+(d*ln(x)))+(e*x)))))",
         Function := "(Alpha+(Beta/(1+exp((((-1)*Gamma)+(Delta*log(Speed)))+(Epsilon*Speed)))))"]

emep2007[Function == "y=((a+(b*x))+(((c-b)*(1-exp(((-1)*d)*x)))/d))",
         Function := "((Alpha+(Beta*Speed))+(((Gamma-Beta)*(1-exp(((-1)*Delta)*Speed)))/Delta))"]

emep2007[Function == "y=(c+(a*exp(b*x)))",
         Function := "(Gamma+(Alpha*exp(Beta*Speed)))"]

emep2007[Function == "y=((((a*(x^3))+(b*(x^2)))+(c*x))+d)",
         Function := "((((Alpha*(Speed^3))+(Beta*(Speed^2)))+(Gamma*Speed))+Delta)"]

emep2007[Function == "y=(c+(a*exp(((-1)*b)*x)))",
         Function := "(Gamma+(Alpha*exp(((-1)*Beta)*Speed)))"]

emep2007[Function == "y=(1/(((c*(x^2))+(b*x))+a))",
         Function := "(1/(((Gamma*(Speed^2))+(Beta*Speed))+Alpha))"]

emep2007[Function == "y=(a/(1+(b*exp(((-1)*c)*x))))",
         Function := "(Alpha/(1+(Beta*exp(((-1)*Gamma)*Speed))))"]

emep2007[Function == "y=exp((a+(b/x))+(c*ln(x)))",
         Function := "exp((Alpha+(Beta/Speed))+(Gamma*log(Speed)))"]
unique(emep2007$Function)

# add function_id column
emep2007[,Function_ID := paste0("2007_",.GRP), by = Function]
unique(emep2007$Function_ID)

# Simplify 'Speed'
emep2007[1]
data.table::setnames(emep2007,
                     c("Min x (km/h)","Max x (km/h)"),
                     c("Vmin","Vmax"))

# simplify others
emep2007[1]
emep2007[,`:=`(`r2` = NULL,`Chi sq'd` = NULL,`Norm. Chi` = NULL)]
emep2007[,`:=`(`ID Subsegment` = NULL)]

# create a column for 'k' parameter
emep2007[,k := 1]

# add 'Category'
emep2007[,Category := "Buses"]

# add 'RF'
emep2007[,RF := 0]

# check names (comparing with emep2016 and emep2019)
emep2019 %>% names() %>% sort()
emep2016 %>% names() %>% sort()
emep2013 %>% names() %>% sort()
emep2007 %>% names() %>% sort()

# avoid duplicated EF, with only change on 'Mode' character
ColNames <- c("Category","Fuel","Segment","Euro","Technology","Pol","Slope","Load","Vmin","Vmax",
              "Alpha","Beta","Gamma","Delta","Epsilon","Zita","Hta","RF","Function","Function_ID","k","Thita")

# check repetted
emep2007[,.N,by = ColNames][N>1]

# add CO2
# rhc = 1.86 and roc = 0.0
co2_2007 <- data.table::copy(emep2007)[,Pol := "CO2"]
co2_2007[,k := 44.011 / (12.001 + 1.008 * 1.86  + 16 * 0 ) ]

# rbind emep2007
emep2007_final <- data.table::rbindlist(l = list(emep2007,co2_2007))



### overlap between emep2007 and emep2013 ----
# 
# we can see that both emep2007 and emep2013 database 
# has euro "V", so we will check if there are any overlaps
unique(emep2013_final$Euro)
unique(emep2007_final$Euro)
emep2013_final[Euro == "V",.N,by = .(Technology,Pol,Segment)]
# Technology Pol   N
# 1:        EGR  FC 105
# 2:        SCR  FC 105
# 3:        EGR CO2 105
# 4:        SCR CO2 105
emep2007_final[Euro == "V",.N,by = .(Technology,Pol,Segment)]
# Technology Pol   N
# 1:         NA  FC 105
# 2:         NA CO2 105
# So, based on the results above, 
# we will use only Euro "V" stage for emep2013_final
emep2007_final <- emep2007_final[Euro != "V"]


### check how CO2 actually behaves----
# make some comparison
#
tmp_colNames <- colnames(co2_2013)
emep2013b <- data.table::copy(co2_2013)[,.SD,.SDcols = tmp_colNames]
emep2016b <- data.table::copy(co2_2016)[,.SD,.SDcols = tmp_colNames]
emep2007b <- data.table::copy(co2_2007)[,.SD,.SDcols = tmp_colNames]

# euro stages 
emep2013b$Euro %>% unique()
emep2016b$Euro %>% unique()
emep2007b$Euro %>% unique()

# evaluating "V"
tmp_emep2007b <- emep2007b[Euro == "V" & 
                             Segment == "Ubus Std 15 - 18 t" & 
                             #Technology == "SCR" & 
                             Slope == 0 & 
                             Load == 0 &
                             Fuel == "D"]
tmp_emep2013b <- emep2013b[Euro == "VI" & 
                             Segment == "Ubus Std 15 - 18 t" & 
                             Technology == "SCR" & 
                             Slope == 0 & 
                             Load == 0 &
                             Fuel == "D"]
tmp_emep2016b <- emep2016b[Euro == "II" & 
                             Segment == "Ubus Std 15 - 18 t" & 
                             #Technology == "SCR" & 
                             Slope == 0 & 
                             Load == 0 &
                             Fuel == "D"]
tmp_emep2007b
tmp_emep2013b
emep2016_final[Fuel == "CNG" ,]

# speed_func(dt = tmp_emep2007b, speed = 33)
# speed_func(dt = tmp_emep2013b, speed = 33)
# speed_func(dt = tmp_emep2016b, speed = 33)

#### Rbindlist all emission factors and export -----------------
#
# we are not exporting emep2016 because it does not have correct data for
# CO2
#
break()
europe <- data.table::rbindlist(list(emep2019
                                     , emep2016_final
                                     , emep2013_final
                                     , emep2007_final
                                     ),use.names = TRUE)
europe[,GRP := .N,by = names(europe)]
europe <- europe[GRP == 1]
europe[,GRP := NULL]


# export
#
ef_europe_emep_db <- data.table::copy(europe)
usethis::use_data(ef_europe_emep_db,overwrite = TRUE)
rm(list=ls())

