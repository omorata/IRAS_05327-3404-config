##
##  Makefile to run the reduction of the EVLA B-configuration data of
##  IRAS 05327+3404
##
##  O. Morata
##  2018
##

# project name, short name and bands to process
PRJ_NAME=EVLA-IRAS_05327+3404
SNAME=iras_05327+3404
BANDS = X K Q C

ROOT_DIR=/almalustre/home/omorata

HOME_DIR=$(ROOT_DIR)/$(PRJ_NAME)

# names of directories to use
#
BIN_DIR=$(HOME_DIR)/scripts
CFG_DIR=$(HOME_DIR)/config
DATA_DIR=$(HOME_DIR)/data
REDC_DIR=$(HOME_DIR)/reduction
RES_DIR=$(HOME_DIR)/results

# names of external directories to link to
#
EXTDATA_DIR=$(ROOT_DIR)/Data/EVLA/$(PRJ_NAME)
EXTREDC_DIR=$(ROOT_DIR)/Reductions/$(PRJ_NAME)

# directory to check when using init
#
CHECK_DIR=results

# script directories
#
PYTHON_DIR=$(BIN_DIR)/python
BASH_DIR=$(BIN_DIR)/bash

# casa version and name of calibration script
#
CASABIN=casa512
CALIB_SCRIPT=calib_evla.py

# default run option
#
RUNOPT="unattended"

#-- define templates ---------------------------------------------------


# template to define the rules to unpack the data files in the reductions
# directory and also to delete the given band reduction directory
#
define Unpack_Template
unpack-$(1):
	if [ ! -d $(REDC_DIR)/band_$(1) ]; \
	then sh $(BASH_DIR)/unpackms.sh \
	    $(CFG_DIR)/calibration/band_$(1)/$(1)-unpack.conf; \
	fi


clean-$(1): 
	rm -Rf cd reduction/band_$(1)
endef



# template to define the rules to make all the steps in the calibration
# of the data for a given frequency band
#
define Calib_Template
info-$(1): reduction/band_$(1)/log_info
reduction/band_$(1)/log_info:
	@sh $(BASH_DIR)/run_calib_step.sh -s "info" -w $(REDC_DIR)/band_$(1) \
            -c cfgfiles/$(1).config -l log_info


checkdata-$(1): reduction/band_$(1)/log_checkdata
reduction/band_$(1)/log_checkdata:
	@sh $(BASH_DIR)/run_calib_step.sh -s "checkdata" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_checkdata

flagdata-$(1): reduction/band_$(1)/log_flagdata
reduction/band_$(1)/log_flagdata:
	@sh $(BASH_DIR)/run_calib_step.sh -s "flagdata" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_flagdata

clean_info-$(1):
	@cd $(REDC_DIR)/band_$(1)/info && rm -Rf *


moveinfo-$(1):
	echo "moving $(REDC_DIR)/band_$(1)/info to $(RES_DIR)/band_$(1)"
	@mv $(REDC_DIR)/band_$(1)/info $(RES_DIR)/band_$(1)


endef


#-- end definition of templates ----------------------------------------

#-- definition of groups of tasks --------------------------------------

unpack_list =
cleanpack_list=
info_list=
checkdata_list=
flagdata_list=
cleaninfo_list=
moveinfo_list=

$(foreach band, $(BANDS), \
    $(eval unpack_list += $(addsuffix $(band),unpack-)) \
    $(eval cleanpack_list += $(addsuffix $(band),clean-)) \
    $(eval info_list += $(addsuffix $(band),info-)) \
    $(eval checkdata_list += $(addsuffix $(band),checkdata-)) \
    $(eval flagdata_list += $(addsuffix $(band),flagdata-)) \
    $(eval cleaninfo_list += $(addsuffix $(band),cleaninfo-)) \
    $(eval moveinfo_list += $(addsuffix $(band),moveinfo-)) \
)

#-- End of definition of group of tasks --------------------------------


export

.PHONY: init erase unpack cleanpack clean_info
.PHONY: info checkdata flagdata


all:


unpack: $(unpack_list)


cleanpack : $(cleanpack_list)


info: $(info_list)


cleaninfo: $(cleaninfo_list)


checkdata: $(checkdata_list)


moveinfo: $(moveinfo_list)


flagdata: $(flagdata_list)


# automatically generate targets for unpacking 
$(foreach band, $(BANDS), \
    $(eval $(call Unpack_Template,$(band))) \
)


# automatically generate targets for calibration
$(foreach band, $(BANDS), \
    $(eval $(call Calib_Template,$(band))) \
)


init:
	sh $(BASH_DIR)/mk_iras_struct.sh


clean: clean_reduction
	rm -Rf results
	rm -f data


clean_reduction:
	(cd reduction && rm -Rf band*)
	rm -Rf reduction



