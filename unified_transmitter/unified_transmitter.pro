TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
        main.cpp \
    usrp_config.cpp

LIBS += -luhd \
        -lboost_system \
        -lboost_thread \
        -lboost_program_options \
        -lboost_filesystem \

HEADERS += \
    usrp_config.h
