/**
* Name: core
*  
* Author: Gamaliel Palomo
* Tags: 
*/


model core
import "constants.gaml"

global{
	file study_area_shp <- file("../includes/area_estudio/area_estudio.shp");
	file bus_stops_shp <- file("../includes/paradas_transporte/paradas.shp");
	file blocks_shp <- file("../includes/area_estudio/manzanas.shp");
	file denue_shp <- file("../includes/denue/denue_ae_2021_05.shp");
	file ppdu_shp <- file("../includes/area_estudio/ppdu.shp");
	file parks_shp <- file("../includes/area_estudio/parks_osm.shp");
	geometry shape <- envelope(study_area_shp);
	
	list block_indicators <- ["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad", "viviendas con internet","acceso a la movilidad","densidad","poblacion primaria"];
	list<float> output_values <- [1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0];
	
	//Indices
	
	
	
	float  walkable_distance	parameter: "walkable distance" 	category: "Environment parameters" 	   <- 0.5#km min:0.1#km max:1#km;
	string  block_indicator	parameter: "Indicator" 	category: "Indicator" 	   <- "poblacion" among:["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad","viviendas con internet","acceso a la movilidad","densidad","poblacion primaria"];
	bool  show_indicator parameter: "show current indicator" 	category: "Environment parameters" 	   <- false;
	bool  show_denue parameter: "show denue" 	category: "Environment parameters" 	   <- true;
	bool  show_bus_stops parameter: "show bus stops" 	category: "Environment parameters" 	   <- false;
	bool  show_population parameter: "show population" 	category: "Environment parameters" 	   <- false;
	bool  show_ppdu parameter: "show ppdu" 	category: "Environment parameters" 	   <- false;
	bool  show_parks parameter: "show parks" 	category: "Environment parameters" 	   <- true;
	bool  show_mobility_heatmap parameter: "show mobility accessibility" 	category: "Environment parameters" 	   <- false;
	
	map<string,int> blocks_max_values;
	float max_mobility_value <- 0.0;
	
	//PPDU
	float ppdu_transparency parameter:"PPDU transparency" category: "Visualization" <- 0.2 min:0.0 max:1.0;
	
	init{
		create school from:denue_shp with:[
			unique_name::string(read("nom_estab")),
			id::string(read("id")),
			activity_type::string(read("codigo_act")),
			nb_employees::int(read("per_ocu"))
		]{
			if not (activity_type in denue_activites){
				do die;
			}
		}
		create study_area from:study_area_shp;
		create bus_stop from:bus_stops_shp with:[routes::string(read("Rutas_que_")),municipality::string(read("Municipio")),class::string(read("Clasificac"))];
		create ppdu from:ppdu_shp with:[
			fid::string(read("fid")),
			Distrito::string(read("Distrito")),
			SubDistrit::string(read("SubDistrit")),
			Clave_de_c::string(read("Clave_de_C")),
			Descripcion::string(read("Descripci0")),
			Clave_del_::string(read("Clave_del_")),
			Descripci1::string(read("Descripci1")),
			Descripci2::string(read("Descripci2")),
			Fecha_de_P::string(read("Fecha_de_P"))
		];
		create block from:blocks_shp with:[
			id::string(read("CVEGEO")),
			population::int(read("POBTOT")),
			nb_0to2::int(read("P_0A2")),
			nb_3to5::int(read("P_3A5")),
			nb_6to11::int(read("P_6A11")),
			nb_12to14::int(read("P_12A14")),
			nb_15to17::int(read("P_15A17")),
			nb_18to24::int(read("P_18A24")),
			nb_65_and_more::int(read("POB65_MAS")),
			
			nb_houses::int(read("TVIVPAR")),
			nb_occuped_houses::int(read("TVIVPARHAB")),
			nb_unoccuped_houses::int(read("VIVPAR_DES ")),
			nb_houses_with_electricity::int(read("VPH_C_ELEC")),
			nb_houses_without_electricity::int(read("VPH_S_ELEC")),
			nb_houses_with_internet::int(read("VPH_INTER")),
			nb_people_elementary::int(read("P_6A11"))
		];
		ask ppdu{
			do die;
		}
		create park from:parks_shp with:[
			type::string(read("fclass")),
			park_name::string(read("name"))
		];
		ppdu_shp <- [];
		blocks_shp <- [];
		bus_stops_shp <- [];
		denue_shp <- [];
		parks_shp <- [];
		study_area_shp <- [];
		
		loop i over:block_indicators{
			blocks_max_values[i] <- max(block collect(each.indicators[i]));
		}
		//ask mobility_heatmap{do filter_cells;}
		
	}
	
	reflex update_output{
		max_mobility_value <- max((mobility_heatmap where(dead(each) = false)) collect(each.accessibility_value));
		output_values[0] <- mean(block collect(each.indicators["poblacion"]/blocks_max_values["poblacion"]));
		output_values[1] <- blocks_max_values["numero de viviendas"]>0?mean(block collect(each.indicators["numero de viviendas"]/blocks_max_values["numero de viviendas"])):0;
		 
		output_values[2] <- blocks_max_values["viviendas habitadas"]>0?mean(block collect(each.indicators["viviendas habitadas"]/blocks_max_values["viviendas habitadas"])):0;
		output_values[3] <- blocks_max_values["viviendas deshabitadas"]>0?mean(block collect(each.indicators["viviendas deshabitadas"]/blocks_max_values["viviendas deshabitadas"])):0; 
		output_values[4] <- blocks_max_values["viviendas con electricidad"]>0?mean(block collect(each.indicators["viviendas con electricidad"]/blocks_max_values["viviendas con electricidad"])):0;
		output_values[5] <- blocks_max_values["viviendas sin electricidad"]>0?mean(block collect(each.indicators["viviendas sin electricidad"]/blocks_max_values["viviendas sin electricidad"])):0;
		output_values[6] <- blocks_max_values["viviendas con internet"]>0?mean(block collect(each.indicators["viviendas con internet"]/blocks_max_values["viviendas con internet"])):0;
		output_values[7] <- max_mobility_value>0 ? mean((mobility_heatmap where(dead(each) = false)) collect(each.accessibility_value/max_mobility_value)) : 0;
		//output_values[7] <- mean((mobility_heatmap where(dead(each) = false)) collect(each.accessibility_value));
		output_values[8] <- blocks_max_values["densidad"]>0?mean(block collect(each.indicators["densidad"]/blocks_max_values["densidad"])):0;
		
	}
	
}

grid mobility_heatmap width:world.shape.width/50 height:world.shape.height/50 frequency:10 parallel:true{
	
	list<mobility_heatmap> active_cells; 
	/*action filter_cells{
		block closest_block <- block closest_to self.location;
		//active_cells <- mobility_heatmap where(each.shape overlaps closest_block);
		if not (self.shape overlaps closest_block.shape ){
			do die;
		}
	}*/
	
	float accessibility_value <- 0.0;
	reflex update_values when:every(2#cycle){
		using topology(world){
			
			bus_stop closest_stop <- bus_stop closest_to self;
			float distance <- closest_stop distance_to self;
			accessibility_value <- distance>=walkable_distance?0.0:(walkable_distance-distance)/walkable_distance;
			
			//float accessibility_intermodal <- tipos_transporte/walkable_distance;
		}
	}
	aspect default{
		if show_mobility_heatmap{
			rgb cell_color;
			cell_color <- rgb(50,50,100,0.9*accessibility_value);
			draw shape color:cell_color empty:false;
		}
	}
}

species bus_stop{
	string routes;
	string municipality;
	string class;
	aspect default{
		if show_bus_stops{
			draw circle(20) color:#yellow;
		}
		
	}
}

species denue{
	string unique_name;
	string id;
	string activity_type;
	int nb_employees;
	aspect default{
		if show_denue{
			draw circle(30) color:rgb(100,100,100,0.6);
		}
	}
}

species school parent:denue{
	int capacity;
	image_file my_icon;
	init{
		 my_icon <- image_file("../includes/img/school.png");
	}
	
	aspect default{
		if show_denue{
			draw circle(60)	 color:rgb(50,50,90,0.8);
		}
	}
}

species road{
}

species block{
	string id;
	map<string,int> indicators;
	list<int> indicators_list;
	
	//Población
	int population;
	int nb_0to2;
	int nb_3to5;
	int nb_6to11;
	int nb_12to14;
	int nb_15to17;
	int nb_18to24;
	int nb_65_and_more;
	
	//Condición de las casas
	int nb_houses;
	int nb_occuped_houses;
	int nb_unoccuped_houses;
	int nb_houses_with_electricity;
	int nb_houses_without_electricity;
	int nb_houses_with_internet;
	int nb_people_elementary;
	float value;
	
	//Values for population analysis
	float pupulation_density;
	
	//Education accessibility variables
	denue closest_school;
	
	//Values from ppdu
	string fid;
	string Distrito;
	string SubDistrit;
	string Clave_de_c;
	string Descripcion;
	string Clave_del_;
	string Descripci1;
	string Descripci2;
	string Fecha_de_P;
	rgb ppdu_color;
	
	init{
		indicators["poblacion"] <- population;
		indicators["numero de viviendas"] <- nb_houses;
		indicators["viviendas habitadas"] <- nb_occuped_houses;
		indicators["viviendas deshabitadas"] <- nb_unoccuped_houses;
		indicators["viviendas con electricidad"] <- nb_houses_with_electricity;
		indicators["viviendas sin electricidad"] <- nb_houses_without_electricity;
		indicators["viviendas con internet"] <- nb_houses_with_internet;
		indicators["densidad"] <- indicators["poblacion"]/shape.area#m;
		closest_school <- (denue at_distance(walkable_distance)) closest_to self;
		/*create people number:nb_people_elementary{
			location <- any_location_in(myself);
		}*/
		ppdu closest_ppdu <- ppdu closest_to(self);
		fid <- closest_ppdu.fid;
		Distrito <- closest_ppdu.Distrito;
		SubDistrit <- closest_ppdu.SubDistrit;
		Clave_de_c <- closest_ppdu.Clave_de_c;
		Descripcion <- closest_ppdu.Descripcion;
		Clave_del_ <- closest_ppdu.Clave_del_;
		Descripci1 <- closest_ppdu.Descripci1;
		Descripci2 <- closest_ppdu.Descripci2;
		Fecha_de_P <- closest_ppdu.Fecha_de_P;
	}
	
	reflex update_education_accessibility when:show_denue{
		closest_school <- (denue at_distance(walkable_distance)) closest_to self;
	}
	
	aspect default{
		
		if show_ppdu{
			if Descripci2 = "Actividades Silvestres"{
				ppdu_color <- rgb (82, 163, 163,ppdu_transparency);
			}
			else if Descripci2 = "Comercial y de servicios" or Descripci2 = "Comercial y de servicios, Habitacional" or Descripci2 = "Comercio"{
				ppdu_color <- rgb (255, 128, 0,ppdu_transparency);
			}
			else if Descripci2 = "Equipamiento"{
				ppdu_color <- rgb (0, 0, 232,ppdu_transparency);
			}
			else if Descripci2 = "Espacios verdes abiertos y recreativos"{
				ppdu_color <- rgb (89, 160, 46,ppdu_transparency);
			}
			else if Descripci2 = "Forestal"{
				ppdu_color <- rgb (183, 235, 165,ppdu_transparency);
			}
			else if Descripci2 = "Habitacional"{
				ppdu_color <- rgb (231, 246, 184,ppdu_transparency);
			}
			else if Descripci2 = "Habitacional, Servicios"{
				ppdu_color <- rgb (231, 246, 184,ppdu_transparency);
			}
			else if Descripci2 = "Industrial"{
				ppdu_color <- rgb (138, 73, 199,ppdu_transparency);
			}
			else if Descripci2 = "Instalaciones especiales e infraestructura"{
				ppdu_color <- rgb (107, 107, 107,ppdu_transparency);
			}
			else if Descripci2 = "Mixto"{
				ppdu_color <- rgb (205, 20, 23,ppdu_transparency);
			}
			else if Descripci2 = "Servicios a la industria y al comercio"{
				ppdu_color <- rgb (229, 146, 50,ppdu_transparency);
			}
			else if Descripci2 = "Sin Información"{
				ppdu_color <- rgb (0, 0, 0,ppdu_transparency);
			}
			draw shape color:ppdu_color;
		}
		if show_indicator{
			value <- indicators[block_indicator]/blocks_max_values[block_indicator];
			draw shape color:rgb(100,100,100,1.0*value);
			if show_denue and not (closest_school = nil){
				draw curve(self.location,closest_school.location,0.0) color:rgb(50,60,50,1.0);
			}
		}
	}
	
}

species study_area{
	aspect default{
		draw shape color:#white empty:true;
	}
}

species ppdu{
	string fid;
	string Distrito;
	string SubDistrit;
	string Clave_de_c;
	string Descripcion;
	string Clave_del_;
	string Descripci1;
	string Descripci2;
	string Fecha_de_P;
}

species park{
	string type;
	string park_name;
	rgb park_color;
	aspect default{
		if show_parks{
			if type = "park"{
				park_color <- rgb (64, 170, 72,255);
			}
			else if type = "forest"{
				park_color <- rgb (219, 223, 66,255);
			}
			draw shape color:park_color;
		}
	}
}

species people skills:[moving]{
	aspect default{
		if show_population{
			draw circle(8) color:rgb(50,50,100,0.6);
		}
	}
}
species building{
	
}
species vehicle skills:[moving]{
	
}