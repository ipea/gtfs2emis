# Patch ef_europe_emep_db: FC rows stored as MJ/km (issue #110)
#
# The 1138 FC rows with Function_ID "2019_1" (2016 guidebook sheet) have the
# same coefficients as the EC rows: they are energy consumption in MJ/km, not
# fuel consumption in g/km. The sources of ef_europe_emep_db.R are offline
# (HTTP 410), so the shipped data is patched here instead of rebuilt.
#
# Source: EMEP/EEA air pollutant emission inventory guidebook 2019,
# 1.A.3.b.i-iv, Table 3-28 (net calorific values), Table 3-29 (H:C ratios)
# and equation 16 (CO2 from fuel consumption).

library(data.table)

load("data/ef_europe_emep_db.rda")
db <- data.table::copy(ef_europe_emep_db)
stopifnot(nrow(db) == 9913)

# net calorific values [MJ/kg] (Table 3-28)
ncv <- c("D" = 42.695, "BD" = 37.3, "CNG" = 48)

idx_fc <- db$Pol == "FC" & db$Function_ID == "2019_1"
idx_cng_co2 <- db$Pol == "CO2" & db$Fuel == "CNG" & db$Function_ID == "2019_1"
stopifnot(sum(idx_fc) == 1138, sum(idx_cng_co2) == 4)
stopifnot(all(db$Fuel[idx_fc] %in% names(ncv)))

# FC [g/km] = EC [MJ/km] / NCV [MJ/kg] * 1000
db[idx_fc, k := 1000 / ncv[Fuel]]

# CNG CO2 [g/km] = FC [g/km] * 44.011 / (12.011 + 1.008 * rH:C), rH:C = 4
# (equation 16, Table 3-29). This replaces the old k, which used MJ/km and
# the diesel ratio (12.001 + 1.008 * 1.86).
db[idx_cng_co2, k := (1000 / ncv[["CNG"]]) * 44.011 / (12.011 + 1.008 * 4)]

# Where a key also has a 2007/2013 FC row (diesel Euro I/II/III and V), keep
# that row: diesel CO2 is derived from it. The converted diesel IV SCR/EGR and
# VI DPF+SCR rows are kept but not reached, because ef_europe_emep() resolves
# FC to tech "-" for Euro IV and "SCR" for Euro VI.
key <- c("Fuel", "Segment", "Euro", "Technology", "Pol", "Slope", "Load")
old_fc <- unique(db[Pol == "FC" & Function_ID != "2019_1", ..key])
dup <- db[old_fc, on = key, which = TRUE, nomatch = NULL]
dup <- dup[db$Function_ID[dup] == "2019_1"]
stopifnot(length(dup) == 525)
db <- db[-dup]

stopifnot(nrow(db) == 9388, !anyDuplicated(db, by = key))

ef_europe_emep_db <- db
usethis::use_data(ef_europe_emep_db, overwrite = TRUE, version = 2)
