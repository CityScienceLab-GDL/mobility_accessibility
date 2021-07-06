/**
* Name: core
*  
* Author: Gamaliel Palomo
* Tags: 
*/


model core

global{
	file study_area_shp <- file("../includes/area_estudio/area_estudio.shp");
	file bus_stops_shp <- file("../includes/paradas_transporte/paradas.shp");
	file blocks_shp <- file("../includes/area_estudio/manzanas.shp");
	geometry shape <- envelope(study_area_shp);
	
	list block_indicators <- ["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad", "viviendas con internet"];
	
	float  walkable_distance	parameter: "walkable distance" 	category: "Environment parameters" 	   <- 0.5#km min:0.1#km max:1#km;
	string  block_indicator	parameter: "Indicador de manzana" 	category: "GUI" 	   <- "poblacion" among:["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad","viviendas con internet"];
	
	map<string,int> blocks_max_values;
	
	init{
		create bus_stop from:bus_stops_shp with:[routes::string(read("Rutas_que_")),municipality::string(read("Municipio")),class::string(read("Clasificac"))];
		create block from:blocks_shp with:[
			id::string(read("CVEGEO")),
			population::int(read("POBTOT")),
			nb_houses::int(read("TVIVPAR")),
			nb_occuped_houses::int(read("TVIVPARHAB")),
			nb_unoccuped_houses::int(read("VIVPAR_DES ")),
			nb_houses_with_electricity::int(read("VPH_C_ELEC")),
			nb_houses_without_electricity::int(read("VPH_S_ELEC")),
			nb_houses_with_internet::int(read("VPH_INTER"))
		];
		blocks_shp <- [];
		loop i over:block_indicators{
			blocks_max_values[i] <- max(block collect(each.indicators[i]));
		}
	}
}

species bus_stop{
	string routes;
	string municipality;
	string class;
	aspect default{
		draw circle(20) color:#yellow;
	}
}
species road{
	
}
species block{
	string id;
	map<string,int> indicators;
	list<int> indicators_list;
	int population;
	int nb_houses;
	int nb_occuped_houses;
	int nb_unoccuped_houses;
	int nb_houses_with_electricity;
	int nb_houses_without_electricity;
	int nb_houses_with_internet;
	float value;
	
	init{
		indicators["poblacion"] <- population;
		indicators["numero de viviendas"] <- nb_houses;
		indicators["viviendas habitadas"] <- nb_occuped_houses;
		indicators["viviendas deshabitadas"] <- nb_unoccuped_houses;
		indicators["viviendas con electricidad"] <- nb_houses_with_electricity;
		indicators["viviendas sin electricidad"] <- nb_houses_without_electricity;
		indicators["viviendas con internet"] <- nb_houses_with_internet;
	}
	
	
	aspect default{
		value <- indicators[block_indicator]/blocks_max_values[block_indicator];
		draw shape color:rgb(255*value,255-255*value,100,0.5);
	}
}
species people skills:[moving]{
	
}
species building{
	
}
species vehicle skills:[moving]{
	
}