/**
* Name: core
* Based on the internal empty template. 
* Author: Luis Villela and Gamaliel Palomo
* Tags: 
*/


model core

global{
	
	file study_area_shp <- file("../includes/area_estudio/area_estudio.shp");
	file bus_stops_shp <- file("../includes/paradas_transporte/paradas.shp");
	file blocks_shp <- file("../includes/area_estudio/manzanas.shp");
	geometry shape <- envelope(study_area_shp);
	
	float  walkable_distance	parameter: "walkable distance" 	category: "Environment parameters" 	   <- 0.5#km min:0.1#km max:1#km;
	
	init{
		create study_area from:study_area_shp with:[id::int(read("fid")),ha::float(read("ha"))];
		create bus_stop from:bus_stops_shp with:[classification::string(read("Clasificac")),routes::string(read("Rutas_que_")),municipality::string(read("Municipio"))];
	}
}

species study_area{
	int id;
	float ha;
	aspect default{
		draw shape empty:true border:#blue width:2.0;
	}
}

species bus_stop{
	string classification;
	string routes;
	string municipality;
	aspect default{
		draw circle(30) color:#green;
	}
}

species block{
	aspect default{
		
	}
}

grid heatmap width:100 height:100 {
	float accessibility_value <- 0.0;
	reflex update_values{
		using topology(world){
			bus_stop closest_stop <- bus_stop closest_to self;
			float distance <- closest_stop distance_to self;
		accessibility_value <- distance>=walkable_distance?0.0:(walkable_distance-distance)/walkable_distance;
		}
	}
	aspect default{
		draw shape color:rgb(255*(1-accessibility_value),255*accessibility_value,50,0.5) empty:false;
	}
}


experiment GUI type:gui{
	output{
		display Scenario type:opengl{
			species study_area aspect:default;
			species bus_stop aspect:default;
			species heatmap aspect:default;
		}
	}
}