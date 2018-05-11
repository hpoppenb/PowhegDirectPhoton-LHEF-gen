# PowhegDirectPhoton-LHEF-gen
everything you need for powheg event generation (LHEF files)

## how to get powheg events ##
The simplest way to generate powheg events is running 'phwg_main' in your powheg-process directory
from a directory, where you have a config file 'powheg.input' containing the configuration (PDFs,
beam energies, cut on minimum momentum transfer ('bornktmin') etc).
(For compiling 'pwhg_main', do 'make pwhg_main' in the process directory, and make sure the Makefile
therein points to lhapdf and looptools, which are required.)

## the four powheg stages ##
Before powheg outputs any LHEF files (= events), it computes an importance sampling grid (stage 1) for
integration of the inclusive cross-section (stage 2), followed by the generation of upper bounding
definition for radiation (stage 3). Only then (stage 4) comes the generation of LHEF files.

## run script ##
There is a script 'run.sh' which allows to run the single stages. This is handy, because stage 1-3 only
need to run once for a given configuration, i.e. the output of stages 1-3 can be taken as a basis for 
stage 4. You only need to provide different seeds for stage 4 (given by the file pwgseeds.dat).
The steering by the script happens by simple text manipulation of the template config file
'powheg.input-save'.

## scale/pdf variations ##
The script 'run.sh' also helps running scale/pdf variations on existing LHEF files. They are handled
as stage 5 (scale var) and stage 6 (pdf var).

## how to run the script 'run.sh' ##
The script asks for 7 arguments, corresponding to the six stages + number of cpu cores to use. Examples:
- running the preparation phases using one core: ./run.sh 1 1 1 0 0 0 1
- generating events using one core: ./run.sh 0 0 0 1 0 0 1
- running pdf variations on existing LHEF files using eight cores : ./run.sh 0 0 0 0 0 1 8

NB: a file 'timings.txt' will hold the date and time, where a stage started, so you can better figure out
time consumption.

## parameters in the script 'run.sh' ##
You can change in the script where to look for 'pwhg_main' and 'powheg.input-save'.
In case of pdf variations, you have to set the number of pdf error sets ('ERRSETS'). e.g.:
You generated events with the PDF nCTEQ15FullNuc_208_82 (LHAPDF ID 103100) and would like to
apply pdf variation. You set the number of error pdfs (here: 32) and then, running the script with the pdf
variation argument will change the lhapdf id in 'powheg.input-save' to numbers 103101..103132 and run each
PDF with the reweighting feature of powheg box v2.

## how to check on negative weights ##
After running stages 1-3, the fil 'pwg-*-stat.dat' will tell you the negative weight fraction, which should
be way below 1%, at best. Negative weight fractions become large for very small bornsuppfact/bornktmin.