prj_open "C:/Users/Kumar Lab/Desktop/Jasper/SERDES_PCS_Generation/SERDES_PCS_Generation.rdf"
prj_run Synthesis -impl impl_1
prj_run Map -impl impl_1
prj_run PAR -impl impl_1
prj_run Export -impl impl_1 -task Bitgen
prj_close
exit
