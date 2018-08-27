##
##  Makefile to run the reduction of the EVLA B-configuration data of
##  IRAS 05327+3404
##
##  O. Morata
##  2018
##

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

RUNOPT="unattended"
CASABIN=casa512

PYTHON_DIR=$(BIN_DIR)/python
BASH_DIR=$(BIN_DIR)/bash

CALIB_SCRIPT=calib_evla.py

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

#info-$(1): reduction/band_$(1)/info/$(SNAME)-$(1)_obslist.txt
#reduction/band_$(1)/info/$(SNAME)-$(1)_obslist.txt:
#checkdata-$(1): reduction/band_$(1)/info/checkdata.done
#reduction/band_$(1)/info/checkdata.done:

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
endef



#-- end definition of templates ----------------------------------------

unpackstr =
cleanpackstr=
infostr=
checkdata=
$(foreach band, $(BANDS), \
    $(eval unpackstr += $(addsuffix $(band),unpack-)) \
    $(eval cleanpackstr += $(addsuffix $(band),clean-)) \
    $(eval infostr += $(addsuffix $(band),info-)) \
    $(eval checkdatastr += $(addsuffix $(band),checkdata-)) \
)


export

.PHONY: init erase unpack cleanpack
all:


unpack: $(unpackstr)


cleanpack : $(cleanpackstr)


info: $(infostr)



checkdata: $(checkdatastr)

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



