##
##  Makefile to run the reduction of the EVLA B-configuration data of
##  IRAS 05327+3404
##
##  O. Morata
##  2018
##

##-- Project info ------------------------------------------------------
#
# project name, general prefix, and bands to process
#
PRJ_NAME=EVLA-IRAS_05327+3404
SNAME=iras_05327+3404
BANDS = X K Q C
#
##-- end project info --------------------------------------------------

##-- Directory set-up --------------------------------------------------
#
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
#
##-- End of directory set-up -------------------------------------------

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


saveinfo-$(1): reduction/band_$(1)/log_info reduction/band_$(1)/log_checkdata
	@echo "moving $(REDC_DIR)/band_$(1)/info to $(RES_DIR)/band_$(1)"
	@mv $(REDC_DIR)/band_$(1)/info $(RES_DIR)/band_$(1)


caldata-$(1): reduction/band_$(1)/log_caldata


reduction/band_$(1)/log_caldata:  reduction/band_$(1)/log_flagdata
	@sh $(BASH_DIR)/run_calib_step.sh -s "caldata" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_caldata


applycal-$(1): reduction/band_$(1)/log_applycal


reduction/band_$(1)/log_applycal: reduction/band_$(1)/log_caldata
	@sh $(BASH_DIR)/run_calib_step.sh -s "applycal" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_applycal


checkcal-$(1): reduction/band_$(1)/log_checkcal


reduction/band_$(1)/log_checkcal:  reduction/band_$(1)/log_applycal
	@sh $(BASH_DIR)/run_calib_step.sh -s "checkcal" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_checkcal


savecalinfo-$(1): reduction/band_$(1)/log_checkcal
	@echo "moving cal"
	@mv $(REDC_DIR)/band_$(1)/cal/* $(RES_DIR)/band_$(1)/calib_info


splits-$(1): reduction/band_$(1)/log_splits


reduction/band_$(1)/log_splits: reduction/band_$(1)/log_applycal
	@sh $(BASH_DIR)/run_calib_step.sh -s "splitdata" \
            -w $(REDC_DIR)/band_$(1) -c cfgfiles/$(1).config \
            -l log_splits


savesplits-$(1): splits-$(1)
	@echo "moving splits"
	@mv $(REDC_DIR)/band_$(1)/splits/* $(RES_DIR)/band_$(1)/splits

endef


#-- end definition of templates ----------------------------------------

#-- definition of groups of tasks --------------------------------------

unpack_list =
cleanpack_list=
info_list=
checkdata_list=
flagdata_list=
cleaninfo_list=
saveinfo_list=
caldata_list=
applycal_list=
checkcal_list=
savecalinfo_list=
splits_list=
savesplits_list=

$(foreach band, $(BANDS), \
    $(eval unpack_list += $(addsuffix $(band),unpack-)) \
    $(eval cleanpack_list += $(addsuffix $(band),clean-)) \
    $(eval info_list += $(addsuffix $(band),info-)) \
    $(eval checkdata_list += $(addsuffix $(band),checkdata-)) \
    $(eval flagdata_list += $(addsuffix $(band),flagdata-)) \
    $(eval cleaninfo_list += $(addsuffix $(band),cleaninfo-)) \
    $(eval saveinfo_list += $(addsuffix $(band),saveinfo-)) \
    $(eval caldata_list += $(addsuffix $(band),caldata-)) \
    $(eval applycal_list += $(addsuffix $(band),applycal-)) \
    $(eval checkcal_list += $(addsuffix $(band),checkcal-)) \
    $(eval savecalinfo_list += $(addsuffix $(band),savecalinfo-)) \
    $(eval splits_list += $(addsuffix $(band),splits-)) \
    $(eval savesplits_list += $(addsuffix $(band),savesplits-)) \
)

#-- End of definition of group of tasks --------------------------------


export

.PHONY: init erase unpack cleanpack clean_info
.PHONY: info checkdata flagdata caldata applycal checkcal splits
.PHONY: saveinfo savecalinfo savesplits saveall


all: saveall


nall: info checkdata checkcal splits


saveall: saveinfo savecalinfo savesplits


unpack: $(unpack_list)


cleanpack : $(cleanpack_list)


info: $(info_list)


cleaninfo: $(cleaninfo_list)


checkdata: $(checkdata_list)


saveinfo: $(saveinfo_list)


flagdata: $(flagdata_list)


caldata: $(caldata_list)


applycal: $(applycal_list)


checkcal: $(checkcal_list)


savecalinfo: $(savecalinfo_list)


splits: $(splits_list)


savesplits: $(savesplits_list)


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
