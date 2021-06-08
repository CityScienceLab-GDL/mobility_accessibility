/**
* Name: core
* Based on the internal empty template. 
* Author: Luis Villela and Gamaliel Palomo
* Tags: 
*/


model core

global{
	
	file study_area_shp <- file("../includes/area_estudio/area_estudio.shp");
	geometry shape <- envelope(study_area_shp);
	
	init{
		create stdy_area from:study_area_shp with:[id::int(read("fid")),ha::float(read("ha"))];
	}
}

species stdy_area{
	int id;
	float ha;
	aspect default{
		draw shape color:#blue border:#white width:2.0;
	}
}


experiment GUI type:gui{
	output{
		display Scenario type:opengl{
			species stdy_area aspect:default;
		}
	}
}