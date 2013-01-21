# do all of the core cofiguration work.
# configuration work basically means creating lots of
# lists of source files, search paths, libraries, etc.
#
ifndef OF_ROOT
    OF_ROOT= ../../..
endif

ifndef PROJECT_ROOT
    PROJECT_ROOT= .
endif


# define the OF_SHARED_MAKEFILES location
OF_SHARED_MAKEFILES_PATH=$(OF_ROOT)/libs/openFrameworksCompiled/project/makefileCommon

############################## FLAGS ###########################################
# OF CORE LIBRARIES SEARCH PATHS (-L ...) (not used during core compilation, but 
#    variables are used during project compilation)
################################################################################

# generate a list of all third party libs, excluding the compiled openFrameworkslibrary.
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
ALL_OF_CORE_THIRDPARTY_LIB_SEARCH_PATHS = $(shell find $(OF_LIBS_PATH)/*/lib/$(ABI_LIB_SUBPATH) -type d -not -path "*/openFrameworksCompiled/*" | grep -v "/\.[^\.]")

# filter out all excluded paths defined in the platform config files.
OF_CORE_THIRDPARTY_LIBS_SEARCH_PATHS = $(filter-out $(CORE_EXCLUSIONS),$(ALL_OF_CORE_THIRDPARTY_LIB_SEARCH_PATHS))


################################################################################
# OF CORE LIBRARIES (-l ...) (not used during core compilation, but variables are 
#    used during project compilation)
################################################################################

# construct the full paths of the core's platform specific static libs 
ALL_OF_CORE_LIBS_PLATFORM_LIB_PATHS = $(OF_LIBS_PATH)/*/lib/$(ABI_LIB_SUBPATH)

# create a list of all core platform libraries
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
ALL_OF_CORE_LIBS_PATHS = $(shell find $(ALL_OF_CORE_LIBS_PLATFORM_LIB_PATHS) -type d -not -path "*/openFrameworksCompiled/*" 2> /dev/null | grep -v "/\.[^\.]" )

# create a list of all core lib directories that have libsorder.make
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
ALL_OF_CORE_LIBSORDER_MAKE_FILES = $(shell find $(ALL_OF_CORE_LIBS_PLATFORM_LIB_PATHS) -name libsorder.make -not -path "*/openFrameworksCompiled/*" 2> /dev/null | grep -v "/\.[^\.]" )

# create a list of all of the core libs that require ordering
OF_CORE_LIBS_THAT_NEED_ORDER = $(subst /lib/$(ABI_LIB_SUBPATH)/libsorder.make,,$(ALL_OF_CORE_LIBSORDER_MAKE_FILES))

# create a list of all of the platform libs that DO NOT require ordering
# by removing those that do from the list of all platform libraries
OF_CORE_LIBS_THAT_DONT_NEED_ORDER = $(filter-out $(OF_CORE_LIBS_THAT_NEED_ORDER),$(subst /lib/$(ABI_LIB_SUBPATH),,$(ALL_OF_CORE_LIBS_PATHS)))

# create a list of all static libs in the core lib dir, using only 
# the static libs that don't need order
# 2> /dev/null consumes file not found errors from find searches
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
# TODO: create a varaible for core specific static lib suffix
OF_CORE_LIBS_PLATFORM_LIBS_STATICS = $(shell find $(addsuffix /lib/$(ABI_LIB_SUBPATH),$(OF_CORE_LIBS_THAT_DONT_NEED_ORDER)) -name *.a 2> /dev/null | grep -v "/\.[^\.]" )
# create a list of all static lib files for the libs that need order
# NOTE. this is the most unintuitive line of make script magic in here
# How does it work?
# 1. Explode each libsorder.make file using cat.  
# 2. For each lib listed in the libsorder.make file, look back at the
#    _original_ path for the libsorder.make file itself, and construct 
#    a path for each of the ordered static libs.  Thus, each exploded 
#    static lib will get its path from the path of the libsorder.make 
#    in which it was listed.
# 3. Add all of them to the ordered files.
#    sed 's/[ ]*#.*//g' strips all comments beginning with #
#    (to escape # in make, you must use \#)
#    sed '/^$/d' removes all empty lines
#    (to escape $ in make, you must use $$)
OF_CORE_LIBS_PLATFORM_LIBS_STATICS += $(foreach v,$(ALL_OF_CORE_LIBSORDER_MAKE_FILES),$(foreach vv,$(shell cat $(v) 2> /dev/null | sed 's/[ ]*\#.*//g' | sed '/^$$/d'),$(addprefix $(subst libsorder.make,,$(v)),$(vv))))

# grep -v "/\.[^\.]" will exclude all .hidden folders and files
ifeq ($(PLATFORM_OS),Linux)
	ALL_OF_CORE_THIRDPARTY_SHARED_LIBS := $(shell find $(OF_LIBS_PATH)/*/lib/$(ABI_LIB_SUBPATH)/*.so -not -path "*/openFrameworksCompiled/*" 2> /dev/null | grep -v "/\.[^\.]")
else
	ifeq ($(PLATFORM_OS),Darwin)
		ALL_OF_CORE_THIRDPARTY_SHARED_LIBS := $(shell find $(OF_LIBS_PATH)/*/lib/$(ABI_LIB_SUBPATH)/*.dylib -not -path "*/openFrameworksCompiled/*" 2> /dev/null | grep -v "/\.[^\.]")
	endif
endif

# add in any libraries that were explicitly listed in the platform config files.
OF_CORE_THIRDPARTY_STATIC_LIBS := $(filter-out $(CORE_EXCLUSIONS),$(OF_CORE_LIBS_PLATFORM_LIBS_STATICS))
OF_CORE_THIRDPARTY_STATIC_LIBS += $(PLATFORM_STATIC_LIBRARIES)

# add in any libraries that were explicitly listed in the platform config files.
OF_CORE_THIRDPARTY_SHARED_LIBS := $(PLATFORM_SHARED_LIBRARIES)

#TODO what to do with shared libs?
OF_CORE_THIRDPARTY_SHARED_LIBS += $(filter-out $(CORE_EXCLUSIONS),$(ALL_OF_CORE_THIRDPARTY_SHARED_LIBS))


################################################################################
# OF PLATFORM LDFLAGS
################################################################################

OF_CORE_LIBRARY_LDFLAGS = $(addprefix -L,$(OF_CORE_THIRDPARTY_LIBS_SEARCH_PATHS))
OF_CORE_LIBRARY_LDFLAGS += $(addprefix -L,$(PLATFORM_LIBRARY_SEARCH_PATHS))


################################################################################
# DEBUG INFO
################################################################################
ifdef MAKEFILE_DEBUG
    $(info =============================configure.core.flags.make========================)   
    $(info ---OF_CORE_LIBS_LDFLAGS---)
    $(foreach v, $(OF_CORE_LIBS_LDFLAGS),$(info $(v)))
    
    $(info ---OF_CORE_LIBS---)
    $(foreach v, $(OF_CORE_LIBS),$(info $(v)))
endif

################################# ADDONS ######################################

ifdef MAKEFILE_DEBUG
    $(info ===================ADDONS================)
endif

# check to make sure OF_ROOT is defined
ifndef OF_ROOT
    $(error OF_ROOT is not defined)
endif

ifndef OF_ADDONS_PATH
    $(error OF_ADDONS_PATH is not defined)
endif

# check to make sure ABI_LIB_SUBPATH is defined
ifndef ABI_LIB_SUBPATH
    $(error ABI_LIB_SUBPATH is not defined)
endif

################################################################################
# for reference, please see the following:
# https://github.com/benben/ofxAddonTemplate

# we will process addons if there is an 
# addons.make file OR PLATFORM_REQUIRED_ADDONS is defined
# we do it this way because gnu make can't do logical ORs 
B_PROCESS_ADDONS = 
ifdef PLATFORM_REQUIRED_ADDONS
    B_PROCESS_ADDONS = yes
endif
ifeq ($(findstring addons.make,$(wildcard $(PROJECT_ROOT)/*.make)),addons.make)
    B_PROCESS_ADDONS = yes
endif

# you can't do LOGICAL ORs in make.  So we do this ...
ifdef B_PROCESS_ADDONS
    ############################################################################
    # VALIDATE REQUESTED ADDONS
    ############################################################################

    # create a list of every addon installed in the addons directory
    ALL_INSTALLED_ADDONS = $(subst $(OF_ADDONS_PATH)/,,$(wildcard $(OF_ADDONS_PATH)/*))

    # get a list of all addons listed in addons.make file
    # sed 's/[ ]*#.*//g' strips all comments beginning with #
    # (to escape # in make, you must use \#)
    # sed '/^$/d' removes all empty lines
    # (to escape $ in make, you must use $$)
    REQUESTED_PROJECT_ADDONS := $(shell cat $(PROJECT_ROOT)/addons.make 2> /dev/null | sed 's/[ ]*\#.*//g' | sed '/^$$/d' )

    # deal with platform specfic addons
    # remove any platform specific addons that were already added to the addons.make file
    REQUESTED_PROJECT_ADDONS := $(filter-out $(PLATFORM_REQUIRED_ADDONS),$(REQUESTED_PROJECT_ADDONS))

    # define a function to remove duplicates without using sort, because sort 
    # will place the list in lexicographic order, and we want to respect the 
    # user's addons.make order.  
    remove-dupes-func = $(if $1,$(strip $(word 1,$1) \
                        $(call $0,$(filter-out $(word 1,$1),$1))))

    # remove all duplicates that might be in the addons.make file
    REQUESTED_PROJECT_ADDONS := $(call remove-dupes-func,$(REQUESTED_PROJECT_ADDONS))

    # add platform required addons from the platform configuration file (if needed)
    # add the platform required addons first, so that they are always linked first
    REQUESTED_PROJECT_ADDONS := $(PLATFORM_REQUIRED_ADDONS) $(REQUESTED_PROJECT_ADDONS)

    # create a list requested addons that are actually installed on the system
    VALID_PROJECT_ADDONS = $(filter $(REQUESTED_PROJECT_ADDONS),$(ALL_INSTALLED_ADDONS))

    # create a list of the invalid addons
    INVALID_PROJECT_ADDONS = $(filter-out $(VALID_PROJECT_ADDONS),$(REQUESTED_PROJECT_ADDONS))

    # if any invalid addons are found, throw a warning, but don't cause an error
    ifneq ($(INVALID_PROJECT_ADDONS),)
        $(warning The following unknown addons will be ignored:)
        $(foreach v, $(INVALID_PROJECT_ADDONS),$(warning $(v)))
        # TODO: download and launch requested addons from ofxaddons?
    endif

    # create a list of addons, excluding invalid and platform-specific addons
    PROJECT_ADDONS = $(filter-out $(INVALID_PROJECT_ADDONS),$(REQUESTED_PROJECT_ADDONS))

    ifdef MAKEFILE_DEBUG
        $(info ---PROJECT_ADDONS---)
        $(foreach v, $(PROJECT_ADDONS),$(info $(v)))
        $(info --------------------)
    endif

    ############################################################################
    # PROCESS PROJECT ADDONS IF AVAILABLE
    ############################################################################

    # if the addons list is NOT empty ...
    ifneq ($(PROJECT_ADDONS),)
		include $(OF_SHARED_MAKEFILES_PATH)/config.addons.make
    endif
endif

# generate the list of core libraries
# 2. Add all of the third party static libs defined by the platform config files.
OF_CORE_LIBS := $(OF_CORE_THIRDPARTY_STATIC_LIBS)
# 2. Add all of the third party shared libs defined by the platform config files.
OF_CORE_LIBS += $(OF_CORE_THIRDPARTY_SHARED_LIBS)
# 3. Add all of the core pkg-config OF libs defined by the platform config files.
CORE_PKG_CONFIG_LIBRARIES += $(PROJECT_ADDONS_PKG_CONFIG_LIBRARIES)
ifneq ($(strip $(CORE_PKG_CONFIG_LIBRARIES)),)
	OF_CORE_LIBS += $(shell pkg-config "$(CORE_PKG_CONFIG_LIBRARIES)" --libs)
endif
# 4. Add the libraries defined in the platform config files.
OF_CORE_LIBS += $(addprefix -l,$(PLATFORM_LIBRARIES))

# add the list of addon includes
ifneq ($(strip $(PROJECT_ADDONS_PKG_CONFIG_LIBRARIES)),)
	OF_CORE_INCLUDES_CFLAGS += $(shell pkg-config "$(PROJECT_ADDONS_PKG_CONFIG_LIBRARIES)" --cflags)
endif

################################################################################
# CLEAN PROJECT EXCLUSIONS 
################################################################################

OF_PROJECT_EXCLUSIONS := $(strip $(PROJECT_EXCLUSIONS))

# add defaults here TODO: should these always be 
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/bin
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/obj
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/.git
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/bin%
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/obj%
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/.git/%
OF_PROJECT_EXCLUSIONS += $(PROJECT_ROOT)/%.xcodeproj


################################################################################
# PROJECT SOURCE FILES
################################################################################

# exclude all items from source according to the config.make file

# create a list of all dirs in the project root that might be valid project
# source directories 
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
ALL_OF_PROJECT_SOURCE_PATHS = $(shell find $(PROJECT_ROOT) -mindepth 1 -type d | grep -v "/\.[^\.]")

# be included as locations for header searches via 
TMP_SOURCE_PATHS = $(filter-out $(OF_PROJECT_EXCLUSIONS),$(ALL_OF_PROJECT_SOURCE_PATHS))

# legacy exclusion
#ifdef EXCLUDE_FROM_SOURCE
#    SED_EXCLUDE_FROM_SRC = $(shell echo  $(EXCLUDE_FROM_SOURCE) | sed 's/\,/\\|/g')\|^\..*\|\/\..*
#    OF_PROJECT_SOURCE_PATHS = $(shell echo $(TMP_SOURCE_PATHS) | sed s/.\\/// | grep -v "$(SED_EXCLUDE_FROM_SRC)")
#else
#    OF_PROJECT_SOURCE_PATHS = $(TMP_SOURCE_PATHS)
#endif
    
OF_PROJECT_SOURCE_PATHS = $(TMP_SOURCE_PATHS)

ifdef MAKEFILE_DEBUG
    $(info ---OF_PROJECT_SOURCE_PATHS---)
    $(foreach v, $(OF_PROJECT_SOURCE_PATHS),$(info $(v)))

    $(info ---OF_PROJECT_EXCLUSIONS---)
    $(foreach v, $(OF_PROJECT_EXCLUSIONS),$(info $(v)))
endif

# find all sources inside the project's source directory (recursively)
# grep -v "/\.[^\.]" will exclude all .hidden folders and files
OF_PROJECT_SOURCE_FILES = $(shell find $(OF_PROJECT_SOURCE_PATHS) -maxdepth 1 -name "*.cpp" -or -name "*.c" -or -name "*.cc" -or -name "*.cxx"  | grep -v "/\.[^\.]")

################################################################################
# PROJECT HEADER INCLUDES (-I ...)
################################################################################

OF_PROJECT_INCLUDES := $(filter-out $(OF_PROJECT_EXCLUSIONS),$(OF_PROJECT_SOURCE_PATHS))
OF_PROJECT_INCLUDES += $(filter-out $(OF_PROJECT_EXCLUSIONS),$(PROJECT_ADDONS_INCLUDES))

OF_PROJECT_INCLUDES_CFLAGS = $(addprefix -I,$(OF_PROJECT_INCLUDES))

ifdef MAKEFILE_DEBUG
    $(info ---OF_PROJECT_INCLUDES_CFLAGS---)
    $(foreach v, $(OF_PROJECT_INCLUDES_CFLAGS),$(info $(v)))
endif

################################################################################
# PROJECT LIBRARIES (-l ...) (not used during core compilation, but vars are 
#    used during project compilation)
################################################################################

# TODO - do we look for search paths or search ... or ?
# TODO - can libs be included in the template?
# TODO - + frameworks?
OF_PROJECT_LIBS := 
OF_PROJECT_LIBS += $(PROJECT_ADDONS_LIBS)
#OF_PROJECT_LIBS_LDFLAGS = $(addprefix -l,$(OF_PROJECT_LIBS))

################################################################################
# PROJECT DEFINES
################################################################################

OF_PROJECT_DEFINES := $(PROJECT_DEFINES)
OF_PROJECT_DEFINES += $(PROJECT_ADDONS_DEFINES)

OF_PROJECT_DEFINES_CFLAGS = $(addprefix -D,$(OF_PROJECT_DEFINES))

################################################################################
# PROJECT CFLAGS
################################################################################

# gather any project CFLAGS
OF_PROJECT_CFLAGS := $(PROJECT_CFLAGS)
OF_PROJECT_CFLAGS += $(USER_CFLAGS) # legacy
OF_PROJECT_CFLAGS += $(OF_PROJECT_DEFINES_CFLAGS)
OF_PROJECT_CFLAGS += $(OF_PROJECT_INCLUDES_CFLAGS)
OF_PROJECT_CFLAGS += $(OF_CORE_BASE_CFLAGS)
OF_PROJECT_CFLAGS += $(OF_CORE_DEFINES_CFLAGS)
OF_PROJECT_CFLAGS += $(OF_CORE_INCLUDES_CFLAGS)


################################################################################
# PROJECT LDLAGS
################################################################################

OF_PROJECT_LDFLAGS := $(PROJECT_LDFLAGS)
OF_PROJECT_LDFLAGS += $(OF_CORE_LIBRARY_LDFLAGS)
OF_PROJECT_LDFLAGS += $(USER_LDLAGS) # legacy
OF_PROJECT_LDFLAGS += $(USER_LIBS)   # legacy
OF_PROJECT_LDFLAGS += $(OF_PROJECT_LIBS_LDFLAGS)
OF_PROJECT_LDFLAGS += $(addprefix -framework ,$(PROJECT_FRAMEWORKS))
OF_PROJECT_LDFLAGS += $(addprefix -framework ,$(PLATFORM_FRAMEWORKS))
OF_PROJECT_LDFLAGS += $(addprefix -framework ,$(PROJECT_ADDONS_FRAMEWORKS))









################################################################################
ifdef MAKEFILE_DEBUG
    $(info ===================compile.project.make=============================)
endif

ifdef PLATFORM_CXX
    CXX = $(PLATFORM_CXX)
endif

ifdef PROJECT_CXX
    CXX = $(PROJECT_CXX)
endif

ifdef PLATFORM_CC
    CC = $(PLATFORM_CC)
endif

ifdef PROJECT_CC
    CC = $(PROJECT_CC)
endif

# TODO: what is this for?
NODEPS = clean

################################################################################
# CFLAGS
################################################################################

# clean it
ALL_CFLAGS =
# add the CFLAGS from Makefiles.examples
ALL_CFLAGS += $(OF_PROJECT_CFLAGS)

# clean up all extra whitespaces in the CFLAGS
CFLAGS = $(strip $(ALL_CFLAGS))

################################################################################
# LDFLAGS
################################################################################

# clean it
ALL_LDFLAGS =

# add the include LDFLAGS from Makefiles.examples
ALL_LDFLAGS += $(OF_PROJECT_LDFLAGS)
ALL_LDFLAGS += $(PLATFORM_LDFLAGS)

# clean up all extra whitespaces in the LDFLAGS
LDFLAGS = $(strip $(ALL_LDFLAGS))

# Optimization flags

PROJECT_OPTIMIZATION_CFLAGS_DEBUG = 
PROJECT_OPTIMIZATION_CFLAGS_DEBUG += 

ifeq ($(findstring Debug,$(TARGET_NAME)),Debug)
	ifeq ($(strip $(PROJECT_OPTIMIZATION_CFLAGS_DEBUG)),)
		OPTIMIZATION_CFLAGS = $(PLATFORM_OPTIMIZATION_CFLAGS_DEBUG)
	else
		OPTIMIZATION_CFLAGS = $(PROJECT_OPTIMIZATION_CFLAGS_DEBUG)
	endif
	
    ifdef PLATFORM_CORELIB_DEBUG_TARGET
    	TARGET_LIBS += $(PLATFORM_CORELIB_DEBUG_TARGET)
    else
    	TARGET_LIBS += $(OF_CORE_LIB_PATH)/libopenFrameworksDebug.a
    endif
endif

ifeq ($(findstring Release,$(TARGET_NAME)),Release)
	ifeq ($(strip $(PROJECT_OPTIMIZATION_CFLAGS_RELEASE)),)
	    OPTIMIZATION_CFLAGS = $(PLATFORM_OPTIMIZATION_CFLAGS_RELEASE)
	else
		OPTIMIZATION_CFLAGS = $(PROJECT_OPTIMIZATION_CFLAGS_RELEASE)
	endif
	
    ifdef PLATFORM_CORELIB_RELEASE_TARGET
    	TARGET_LIBS += $(PLATFORM_CORELIB_RELEASE_TARGET)
    else
    	TARGET_LIBS += $(OF_CORE_LIB_PATH)/libopenFrameworks.a
    endif
endif


################################################################################
# OBJECT AND DEPENDENCY FILES DEFINITIONS
#	Object file paths are generated here (as opposed to with the rest of the 
#   flags) because we want to place them in target-specific folders. We
#   determine targets above. We –could– determine the target info earlier if we
#   wanted to.  It's here because that's approximately where it was in the 
#   legacy makefiles.
################################################################################

# define the subdirectory for our target name

ifdef MAKEFILE_DEBUG
    $(info ---OF_PROJECT_SOURCE_FILES---)
    $(foreach v, $(OF_PROJECT_SOURCE_FILES),$(info $(v)))
endif
ifdef MAKEFILE_DEBUG
    $(info ---OF_PROJECT_DEPENDENCY_FILES---)
    $(foreach v, $(OF_PROJECT_DEPENDENCY_FILES),$(info $(v)))
endif

ifdef ABI
	OF_PROJECT_OBJ_OUPUT_PATH = obj/$(PLATFORM_LIB_SUBPATH)/$(ABI)/$(TARGET_NAME)
else
	OF_PROJECT_OBJ_OUPUT_PATH = obj/$(PLATFORM_LIB_SUBPATH)/$(TARGET_NAME)
endif

OF_PROJECT_OBJ_FILES = $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(patsubst %.cxx,%.o,$(patsubst %.cc,%.o,$(OF_PROJECT_SOURCE_FILES)))))
OF_PROJECT_OBJS = $(subst $(PROJECT_ROOT)/,,$(addprefix $(OF_PROJECT_OBJ_OUPUT_PATH)/,$(OF_PROJECT_OBJ_FILES)))
OF_PROJECT_DEPS = $(patsubst %.o,%.d,$(OF_PROJECT_OBJS))

OF_PROJECT_ADDONS_OBJ_FILES = $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(patsubst %.cxx,%.o,$(patsubst %.cc,%.o,$(PROJECT_ADDONS_SOURCE_FILES)))))

OF_PROJECT_ADDONS_OBJS = 
$(foreach addon_obj, $(OF_PROJECT_ADDONS_OBJ_FILES), \
     $(eval OF_PROJECT_ADDONS_OBJS+= $(patsubst $(OF_ROOT)/addons/$(word 1, $(subst /, ,$(subst $(OF_ROOT)/addons/,,$(addon_obj))))/%, \
                                          $(OF_ROOT)/addons/$(OF_PROJECT_OBJ_OUPUT_PATH)/$(word 1, $(subst /, ,$(subst $(OF_ROOT)/addons/,,$(addon_obj))))/%, \
                                          $(addon_obj))) \
)

OF_PROJECT_ADDONS_DEPS = $(patsubst %.o,%.d,$(OF_PROJECT_ADDONS_OBJS))

OF_PROJECT_DEPENDENCY_FILES = $(OF_PROJECT_DEPS) $(OF_PROJECT_ADDONS_DEPS)

# TODO: deal with shared libs?


ifdef MAKEFILE_DEBUG
    $(info ---OF_PROJECT_DEPENDENCY_FILES---)
    $(foreach v, $(OF_PROJECT_DEPENDENCY_FILES),$(info $(v)))
endif
