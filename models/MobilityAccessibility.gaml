/**
* Name: core
* Based on the internal empty template. 
* Author: Luis Villela and Gamaliel Palomo
* Tags: 
*/


model MobilityAccessibility
import "GAMABrix.gaml"

global{
	
	//CityIO parameters
	bool post_on <- true;
	bool pull_only <- false;
	bool send_first_batch <- false;
	int cycle_first_batch <- 10; 
	
	float step <- 1#h;
	file study_area_shp <- file("../includes/area_estudio/area_estudio.shp");
	file bus_stops_shp <- file("../includes/paradas_transporte/paradas.shp");
	file blocks_shp <- file("../includes/area_estudio/manzanas.shp");
	string city_io_table<-"udg_dcu";
	geometry shape <- envelope(setup_cityio_world());
	//geometry shape <- envelope(study_area_shp);
	
	float  walkable_distance	parameter: "walkable distance" 	category: "Environment parameters" 	   <- 0.5#km min:0.1#km max:1#km;
	bool  show_bus_stops	parameter: "show bus stops" 	category: "Environment parameters" 	   <- false;
	
	init{
		create study_area from:study_area_shp with:[id::int(read("fid")),ha::float(read("ha"))];
		create bus_stop from:bus_stops_shp with:[classification::string(read("Clasificac")),routes::string(read("Rutas_que_")),municipality::string(read("Municipio"))];
		create block from: blocks_shp;
		//create average_accessibility;
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
		if show_bus_stops{
			draw circle(30) color:#green;	
		}
	}
}

species block{
	string geo_id;
	string block_id;
	aspect default{
		draw shape empty:true border:#gray;	
	}
}

grid heatmap width:world.shape.width/50 height:world.shape.height/50 parent:cityio_agent{
	
	//CityScope indicator parameters
	bool is_heatmap<-true;
	
	float accessibility_value <- 0.0;
	reflex update_values when:every(2#cycle){
		using topology(world){
			bus_stop closest_stop <- bus_stop closest_to self;
			float distance <- closest_stop distance_to self;
			accessibility_value <- distance>=walkable_distance?0.0:(walkable_distance-distance)/walkable_distance;
			//float accessibility_intermodal <- tipos_transporte/walkable_distance;
		}
	}
	reflex update_heatmap{
		heatmap_values<-[];
		heatmap_values<+ "Access"::1-accessibility_value;
		heatmap_values<+ "Lack of mobility choices"::accessibility_value;
	}
	aspect default{
		draw shape color:rgb(255*(1-accessibility_value),255*accessibility_value,50,0.5) empty:false;
	}
}

species average_accessibility parent: cityio_agent {
    bool is_numeric<-true;
    string viz_type <- "bar";
    string indicator_name<-"Public transportation";
    
    reflex update_numeric {
    	list values <- heatmap collect (each.accessibility_value);
        numeric_values<-[];
        //numeric_values<+indicator_name::0.3;//mean(values);
    }
}


experiment GUI type:gui{
	output{
		display Scenario type:opengl  draw_env:false{
			species study_area aspect:default;
			species block aspect:default refresh:false;
			species bus_stop aspect:default;
			species heatmap aspect:default;
		}
	}
}