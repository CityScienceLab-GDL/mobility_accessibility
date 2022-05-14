/**
* Name: filesvalidator
* Based on the internal empty template. 
* Author: Gamaliel Palomo, Juan Alvarez
* Tags: 
*/


model CityScope
import "constants.gaml"


global skills:[network]{
	
	//Shape files
	
	//Environmental shapes
	//file new_limits_shp <- file(dcu_limits_filename);
	file dcu_limit_shp <- file(dcu_limits_filename);
	file dcu_satellite_shp <- file(main_shp_path+"environment/envolvente_mesa_imagen_satelital.shp");
	file ccu_limit_shp <- file(main_shp_path+"environment/scenario_limits.shp");
	file ccu_transport_shp <- file(main_shp_path+dcu_transport_filename);
	file ccu_massive_transport_shp <- file(main_shp_path+dcu_massive_transport_filename);
	file cycling_ways_shp <- file(dcu_cycling_way_filename);
	file intervention_areas_shp <- file(main_shp_path+intervention_areas_filename);
	file economic_activities_shp <- file(main_shp_path+economic_activities_filename);
	//file projects_csv <- csv_file(main_csv_path+projects_filename);
	file projects_shp <- file(main_shp_path+projects_shp_filename);
	file allowed_activities_csv <- csv_file(main_csv_path+allowed_activities_by_use_filename);
	
	//Shapes for people flows in case of a cultural event
	file events_roads_shp <- file(events_roads_filename);
	file events_entry_points_shp <- file(events_entry_points_filename);
	file events_location_points_shp <- file(events_locations_filename);
	
	//Scenario 1
	file s1_roads_shp 				<- file(main_shp_path+"scenario1/roads.shp");
	file s1_blocks_shp 				<- file(main_shp_path+"scenario1/blocks.shp");
	file s1_equipment_shp 		<- file(main_shp_path+"scenario1/equipment.shp");
	file s1_grid_shp 					<- file(main_shp_path+"scenario1/grid.shp");
	
	//Scenario 2
	file s2_roads_shp 				<- file(main_shp_path+"scenario2/roads.shp");
	file s2_blocks_shp 				<- file(main_shp_path+"scenario2/blocks.shp");
	file s2_grid_shp 					<- file(main_shp_path+"scenario2/grid.shp");
	
	//Simulation parameters
	//geometry shape <- envelope(dcu_limit_shp);
	geometry shape <- envelope(dcu_limit_shp);
	int scenario <- 1;
	
	
	//Network variables
	graph roads_network;
	graph event_roads_network;
	map<string,path> paths;
	map event_roads_weight;
	map roads_weight;
	
	//Visualization variables
	bool show_satellite <- false parameter:"Satellite" category:"Visualization";
	bool show_intervention_areas <- false parameter:"Intervention areas" category:"Visualization";
	
	//Heatmap  variables
	bool show_heatmap <- false;
	list<heatmap> ccu_heatmap;
	bool show_interactions <- false;
	
	//Indicators  variables
	list<equipment> education_facilities;
	list<equipment> culture_facilities;
	list<equipment> health_facilities;
	list<equipment> sports_facilities;
	list<diversity_grid> div_grid;
	
	//Variables related to interventions
	map<string,list<string>> allowed_activities;
	
	//Indicators variables that are going to be sent to the dashboard
	bool allow_export_data <- false;
	bool write_log <- false;
	//All this indicators are initialized to 0 at each of the 3 scenarios.
	//DIVERSITY
	list<float> dash_day_activities_diversity 				<- [0.0,0.0,0.0];
	list<float> dash_night_activities_diversity 				<- [0.0,0.0,0.0];
	list<float> dash_third_activities_diversity 				<- [0.0,0.0,0.0];
	list<float> dash_knowledge_activities_diversity 	<- [0.0,0.0,0.0];
	//FUNCTIONALITY
	list<float> dash_hab_net_density 							<- [0.0,0.0,0.0];
	list<float> dash_living_place_density 					<- [0.0,0.0,0.0];
	list<float> dash_day_activities_density 					<- [0.0,0.0,0.0];
	list<float> dash_night_activities_density 				<- [0.0,0.0,0.0];
	list<float> dash_innovation_potential 					<- [0.0,0.0,0.0];
	list<float> dash_green_proximity 							<- [0.0,0.0,0.0];
	list<float> dash_public_spaces_proximity 				<- [0.0,0.0,0.0];
	list<float> dash_educational_equipment_proximity 			<- [0.0,0.0,0.0];
	list<float> dash_cultural_equipment_proximity 				<- [0.0,0.0,0.0];
	list<float> dash_health_equipment_proximity 					<- [0.0,0.0,0.0];
	list<float> dash_social_assistance_equipment_proximity <- [0.0,0.0,0.0];
	list<float> dash_intersections_density 								<- [0.0,0.0,0.0];
	list<float> dash_public_transport_coverage						<- [0.0,0.0,0.0];
	list<float>	dash_km_ways_per_hab									<- [0.0,0.0,0.0];
	list<float>	dash_km_ways_per_km2									<- [0.0,0.0,0.0];
	//ENVIRONMENTAL IMPACT
	list<float> dash_energy_requirement 	<- [0.0,0.0,0.0];
	list<float> dash_waste_generation 		<- [0.0,0.0,0.0];
	
	//Visualization variables
	map<int,string> int_to_day <- [1::"Jueves",2::"Viernes",3::"Sábado",4::"Domingo",5::"Lunes",6::"Martes",7::"Miércoles"];

	
	init{
		
		//Simulation specific variables
		step 					<- 2#seconds;
		starting_date 	<- date("2022-5-17 06:00:00");
		
		//Initialize MQTT connection
		write "Initializing MQTT connection";
		do connect to:"localhost" with_name:"cityscope_table";
		
		
		//Create environment agents
		//create ccu_limit from:ccu_limit_shp;
		create ccu_limit from: dcu_limit_shp;
		create transport_station from: ccu_transport_shp with:[type::"bus"];
		create transport_station from: ccu_massive_transport_shp with:[type::"massive",subtype::string(read("Sistema"))];
		create cycling_way from:cycling_ways_shp;
		
		
		//-----------   Create environment agents from scenario 1
		create roads from:s1_roads_shp with:[from_scenario::1];
		create blocks from:s1_blocks_shp with:[from_scenario::1,nb_people::int(read("POB1")),block_area::float(read("shape_area"))]{
			create people number:int(nb_people/10) with:[home_block::self,target_block::one_of(blocks-self)]{
				from_scenario <- 1;
				location <- any_location_in(home_block);
				mobility_type <- select_mobility_mode();
			}
		}
		create economic_unit from:economic_activities_shp with:[from_scenario::1,activity_id::read("codigo_act"),sub_id::read("sec_sub")];
		create equipment from:s1_equipment_shp with:[type::string(read("tipo_equip")),subtype::string(read("cat_sedeso")),from_scenario::1];
		create diversity_grid from:s1_grid_shp with:[night_diversity::float(read("ID_NOCHE")),day_diversity::float(read("ID_DIA")),knowledge_diversity::float(read("ID_CONOCIM")),from_scenario::1];
		
		//-----------   Create environment agents from scenario B
		create blocks from:s2_blocks_shp with:[from_scenario::2,nb_people::int(read("POB1")),block_area::float(read("shape_area"))];
		//create diversity_grid from:s2_grid_shp with:[night_diversity::float(read("ID_NOCHE")),day_diversity::float(read("ID_DIA")),knowledge_diversity::float(read("ID_CONOCIM")),from_scenario::2];
		
		//------------ Create environment agents from scenario Event
		create roads from:events_roads_shp with:[from_scenario::4];
		event_roads_weight <- roads where(each.from_scenario=4) as_map (each::each.shape.perimeter);
		//event_roads_network <- as_edge_graph(roads where(each.from_scenario="event")); 
		event_roads_network <- roads where(each.from_scenario=4) as_intersection_graph 1.0 with_weights event_roads_weight;
		create entry_point from:events_entry_points_shp with:[rate::int(read("porcentaje"))];
		create event_location from:events_location_points_shp with:[capacity::int(read("avg_asiste"))];
		
		//This is to init individual indicators of people
		ask people{
			
			//Mobility accessibility
			int transport_accessibilty_count <- 0;
			list<float> distances <- [];
			transport_station closest_station <- transport_station where(each.type="bus") closest_to self;
			add closest_station distance_to self to:distances;
			closest_station <- transport_station where(each.type="massive" and each.subtype="BRT (Bus Rapid Transit)") closest_to self;
			add closest_station distance_to self to:distances;
			closest_station <- transport_station where(each.type="massive" and each.subtype="Tren Eléctrico") closest_to self;
			add closest_station distance_to self to:distances;
			cycling_way closest_cycling_way <- cycling_way closest_to self;
			add closest_station distance_to self to:distances;
			if distances[0] < 300{transport_accessibilty_count <- transport_accessibilty_count + 1;} 
			if distances[1] < 500{transport_accessibilty_count <- transport_accessibilty_count + 1;}
			if distances[2] < 800{transport_accessibilty_count <- transport_accessibilty_count + 1;}
			if distances[3] < 300{transport_accessibilty_count <- transport_accessibilty_count + 1;}
			mobility_accessibility <- transport_accessibilty_count /4;
			ind_public_transport_coverage <- transport_accessibilty_count >=3;
			
		}
		
		/*ask diversity_grid {
			list<people>my_people <- people where(each.from_scenario = self.from_scenario) inside self;
			self.transportation_access <- mean(my_people collect(each.mobility_accessibility));
		} */
		
		
		//Create road network
		roads_weight <- roads where(each.from_scenario=1) as_map (each:: each.shape.perimeter);
		roads_network <- roads where(each.from_scenario=1) as_intersection_graph 1.0 with_weights roads_weight;
		
		//Create satellital image
		create satellite_background from:dcu_satellite_shp;
		
		//Initialize matrix of allowed activities by use type
		matrix data <- matrix(allowed_activities_csv);
		loop i from:1 to:data.rows-1{
			list<string> tmp;
			loop j from:2 to:data.columns-1{
				if data[j,i] != "NA"{ add data[j,i] to: tmp;}
			}
			add data[0,i]::tmp to:allowed_activities;
		}
		//allowed_activities_by_use_filename
		
		//Create project agent from csv
		/*data <- matrix(projects_csv);
		loop i from: 0 to: data.rows -1{
			create project with:[
				id::data[0,i], 
				block_id::data[1,i],
				project_name::data[2,i],
				population::int(data[3,i]),
				use_type::data[4,i],
				nb_ec_units::int(data[5,i]),
				UBS::int(data[6,i]),
				green_areas_m2::float(data[7,i]),
				building_m2::float(data[8,i]),
				VIV40M::int(data[9,i]),
				VIV60M::int(data[10,i]),
				VIV80M::int(data[11,i])
			];
		}	*/
		create project from:projects_shp with:[id::read("ID_CCU"),block_id::read("ID_BLOCK"),from_scenario::2];
		
		//Create intervention areas
		create intervention_area from:intervention_areas_shp with:[id::read("fid"),area_name::read("nombre"),associated_projects_str::read("id_ccu")]{
			//Lets associate each area to a project in the projects data base created just before
			list<string> valid_project_ids <- project collect(each.id);
			write area_name+ " AP: "+associated_projects_str;
			if associated_projects != nil{
				list<string> str_projects <- split_with(associated_projects_str,",");
				if not empty(str_projects){
					loop p_id over: str_projects{
						if p_id in valid_project_ids{add first(project where(each.id=p_id)) to:associated_projects;}
					}
				}
			}
			
		}	
		
		
		
		//Clean memory
		ccu_limit_shp 				<- [];
		s1_roads_shp 				<- [];
		s1_blocks_shp 				<- [];
		s1_equipment_shp 		<-[];
		s1_grid_shp 					<- [];
		s2_roads_shp 				<- [];
		s2_blocks_shp 				<- [];
		s2_grid_shp 					<- [];
		ccu_transport_shp 		<- [];
		ccu_massive_transport_shp <- [];
		dcu_satellite_shp 		<- [];
		cycling_ways_shp 		<- [];
		intervention_areas_shp 	<- [];
		projects_shp 					<- [];
		events_roads_shp 		<- [];
		events_entry_points_shp 		<- [];
		events_location_points_shp <- [];
		data <- nil;
		
		
		education_facilities 	<- equipment where(each.type="Educación");
		culture_facilities 		<- equipment where(each.type="Cultura");
		health_facilities 			<- equipment where(each.type="Salud");
		sports_facilities			<- equipment where(each.type="Deporte");
		
		list<people>valid_people;
		ask ccu_limit{
			ccu_heatmap 				<- heatmap inside(self);
			div_grid							<- diversity_grid inside(self);
			valid_people <- people inside self;
		}
		ask people{
			if not (self in valid_people){do die;}
		}
		
		write "education:"+ length(education_facilities);
		write "culture:"+ length(culture_facilities);
		write "health:"+ length(health_facilities);
		write "sports:" +length(sports_facilities);
		//Ask people to initialize paths
		//ask people{do init_path;}
		
		
	}
	
	//Reflex to listen to the MQTT topic
	reflex receiveAgent when:has_more_message(){
		message the_message <- fetch_message();
		write "Received: "+the_message.contents;
		// A, B, I, K, L
		string new_string <- the_message.contents;
		list<string> words <-split_with(new_string,",");
		loop w over: words{
			list<string> letters <- split_with(new_string,"/");
			write "Activating polygon: "+letters[0]+", scenario: "+letters[1];
			ask intervention_area where(each.name=letters[0]){
				do activate_scenario(int(letters[1]));
			}
		}
	}
	
	//This reflex is to produce cars flows for the mobility simulation
	reflex generate_car_flows when:sum(event_location collect(each.capacity - each.current_people))>0{
		ask entry_point{
			 
			if flip(self.rate/100){
				event_location tmp_location <- first(event_location where((each.capacity-each.current_people)>0));
				create car with:[from_scenario::4, my_event::tmp_location, location::self.location];
				ask tmp_location{current_people <- current_people - 1;}
			}
			
		}
	}
	
	
	//This reflex exports the data that is going to be read by the dashboard
	reflex compute_export_data when:allow_export_data{
		//Some of the values that are exported by this funcion are computed in other functions.
		
		//1. DIVERSIDAD
		/*
		 dash_day_activities_diversity;OK
		 dash_night_activities_diversity;OK
		 dash_third_activities_diversity;
		 dash_knowledge_activities_diversity;OK
		 */
		 dash_day_activities_diversity[0] <- mean(div_grid where(each.from_scenario=1) collect(each.day_diversity));
		 dash_day_activities_diversity[1] <- mean(div_grid where(each.from_scenario=2) collect(each.day_diversity));
		 dash_night_activities_diversity[0] <- mean(div_grid where(each.from_scenario=1) collect(each.night_diversity));
		 dash_night_activities_diversity[1] <- mean(div_grid where(each.from_scenario=2) collect(each.night_diversity));
		 dash_knowledge_activities_diversity[0] <- mean(div_grid where(each.from_scenario=1) collect(each.knowledge_diversity));
		 dash_knowledge_activities_diversity[1] <- mean(div_grid where(each.from_scenario=2) collect(each.knowledge_diversity));
		 
		 
		//2. FUNCIONALIDAD
		 /*
		dash_hab_net_density;OK
		dash_living_place_density;
		dash_day_activities_density;
		dash_night_activities_density;
		dash_innovation_potential;
		dash_green_proximity;
		dash_public_spaces_proximity;OK
		dash_educational_equipment_proximity;OK
		dash_cultural_equipment_proximity;OK
		dash_health_equipment_proximity;OK
		dash_social_assistance_equipment_proximity;
		dash_intersections_density;
		dash_public_transport_coverage;OK
		dash_km_ways_per_hab;
		dash_km_ways_per_km2;
		*/
		
		dash_hab_net_density[0] <- sum(blocks where(each.from_scenario=1) collect(each.nb_people)) / sum(blocks where(each.from_scenario=1) collect(each.block_area));
		dash_hab_net_density[1] <- sum(blocks where(each.from_scenario=2) collect(each.nb_people)) / sum(blocks where(each.from_scenario=2) collect(each.block_area));
		dash_public_transport_coverage[0] <- length(people where(each.from_scenario =1 and each.ind_public_transport_coverage))/length(people where(each.from_scenario=1));
		dash_public_transport_coverage[1] <- length(people where(each.from_scenario =1 and each.ind_public_transport_coverage))/length(people where(each.from_scenario=2));
		
		
		//3. IMPACTO AMBIENTAL
		 /*
		 dash_energy_requirement;
		 dash_waste_generation;
		 */
		
		
		if (write_log){
			write "--------------------------- DASHBOARD VALUES------------------------------";
			write "DIVERSIDAD";
			write "Diversidad de actividades diurnas: "+dash_day_activities_diversity;
			write "Diversidad de actividades nocturnas: "+dash_night_activities_diversity;	
			write "Diversidad de actividades densas en conocimiento: "+dash_knowledge_activities_diversity;
			
			write "FUNCIONALIDAD";
			write "Densidad neta de habitantes: "+dash_hab_net_density;
			write "Proximidad a espacios públicos abiertos: "+dash_public_spaces_proximity;
			write "Proximidad a equipamientos educativos: "+dash_educational_equipment_proximity;
			write "Proximidad a equipamientos culturales: "+dash_cultural_equipment_proximity;
			write "Proximidad a equipamientos de salud: "+dash_health_equipment_proximity;
			write "Proximidad a transporte alternativo: "+ dash_public_transport_coverage;
			write "";
		}
		
	}
	//This reflex is for saving simulation data in order to be exported to the dashboard
	reflex export_data when:allow_export_data and every(5#cycle){
		save data:[dash_day_activities_diversity[0],
			dash_night_activities_diversity[0],
			dash_knowledge_activities_diversity[0],
			dash_hab_net_density[0],
			dash_public_spaces_proximity[0],
			dash_educational_equipment_proximity[0],
			dash_cultural_equipment_proximity[0],
			dash_health_equipment_proximity[0],
			dash_public_transport_coverage[0]
		] to:"../output/output_a.csv" type:"csv" rewrite:false;
		save data:[dash_day_activities_diversity[1],
			dash_night_activities_diversity[1],
			dash_knowledge_activities_diversity[1],
			dash_hab_net_density[1],
			dash_public_spaces_proximity[1],
			dash_educational_equipment_proximity[1],
			dash_cultural_equipment_proximity[1],
			dash_health_equipment_proximity[1],
			dash_public_transport_coverage[1]
		] to:"../output/output_b.csv" type:"csv" rewrite:false;
	}
	
	
	//Function created to create paths from blocks to blocks
	action pathfinder{
		int valid <- 0;
		int invalid <- 0;
		map<string,bool> computed;
		loop i over:blocks{
			bool is_valid <- true;
			loop j over:blocks{
				if i!=j and not (computed[string(j)+string(i)]){
					roads closest_road <- roads closest_to i;
					point starting_point <- closest_road.shape.points closest_to i;
					roads finish_road <- roads closest_to j;
					point finish_point <- finish_road.shape.points closest_to j;
					path the_path <- path_between(roads_network,starting_point,finish_point);
					if the_path != nil { valid <- valid +1;add string(i)+string(j)::the_path to:paths;	add string(i)+string(j)::true to:computed;}
					else{
						is_valid <- false;
						invalid <- invalid + 1;	
					}
				}
				write "--------------------";
				write "Valid paths: "+valid;
				write "Invalid paths: "+invalid;
			}
			i.valid <- is_valid;
		}
	}
	
	
	//----------  USER INTERACTION  ------------------------------
	//Functions built to update heatmap values according to the input from the user
	//Currently it is under development. We are looking to use fields and mesh to show heatmaps (gama 1.8.2).
	//Currently we use "from_scenario" variable to distiguish the source of data
	
	
	action select_scenario_1{scenario <- 1;}
	action select_scenario_2{scenario <- 2;}
	
	action heatmap2polution{
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ccu_heatmap{
			
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2education{
		ask ccu_heatmap{grid_value <- 0.0;}
		
		//Radar values
		ask blocks where(each.from_scenario = scenario) inside (first(ccu_limit)){
			nb_different_education_equipment <- 0;
			loop class over:education_distances.keys{
				list<equipment> tmp_list <- education_facilities where(each.subtype = class) at_distance(education_distances[class]);
				nb_different_education_equipment <- empty(tmp_list)?nb_different_education_equipment:nb_different_education_equipment+1;
			}
			ind_proximity_2_education_equipment <- nb_different_education_equipment > min_education_equipment;
			ask people where(each.from_scenario = scenario and each.home_block=self){
				ind_education_equipment_proximity <- myself.ind_proximity_2_education_equipment;
			}
			int scenario_index <- scenario = 1?0:1;
			dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		//write length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		
		ask education_facilities {
			//Here we obtain the shape of the block in order to update the grid values related to it
			blocks the_block <- blocks where(each.from_scenario = scenario) closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}
		}
		do spread_value(spread_value_factor);
	}
	action heatmap2culture{
		ask ccu_heatmap{grid_value <- 0.0;}
		
		//Radar values
		ask blocks where(each.from_scenario = scenario) inside (first(ccu_limit)){
			nb_different_cultural_equipment <- 0;
			loop class over:culture_distances.keys{
				list<equipment> tmp_list <- culture_facilities where(each.subtype = class) at_distance(culture_distances[class]);
				nb_different_cultural_equipment <- empty(tmp_list)?nb_different_cultural_equipment:nb_different_cultural_equipment+1;
			}
			ind_proximity_2_cultural_equipment <- nb_different_cultural_equipment > min_culture_equipment;
			float value_sum <- 0.0;
			ask people where(each.from_scenario = scenario and each.home_block=self){
				ind_cultural_equipment_proximity <- myself.ind_proximity_2_cultural_equipment;
				value_sum <- value_sum + (ind_cultural_equipment_proximity?1:0);
			}
			int scenario_index <- scenario = 1?0:1;
			dash_cultural_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_cultural_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		//write length(people where(each.from_scenario=scenario and each.ind_cultural_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		
		
		//Heatmap values
		ask ccu_heatmap{grid_value <- 0.0;}
		ask culture_facilities{
			blocks the_block <- blocks where(each.from_scenario = scenario) closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}		
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2health{
		
		//Radar values
		ask blocks where(each.from_scenario = scenario) inside (first(ccu_limit)){
			nb_different_health_equipment <- 0;
			loop class over:health_distances.keys{
				list<equipment> tmp_list <- health_facilities where(each.subtype = class) at_distance(health_distances[class]);
				nb_different_health_equipment <- empty(tmp_list)?nb_different_health_equipment:nb_different_health_equipment+1;
			}
			ind_proximity_2_health_equipment <- nb_different_health_equipment > min_health_equipment;
			float value_sum <- 0.0;
			ask people where(each.from_scenario = scenario and each.home_block=self){
				ind_health_equipment_proximity <- myself.ind_proximity_2_health_equipment;
				value_sum <- value_sum +(ind_health_equipment_proximity?1:0);
			}
			int scenario_index <- scenario = 1?0:1;
			dash_health_equipment_proximity[scenario_index] <- write length(people where(each.from_scenario=scenario and each.ind_health_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		//write length(people where(each.from_scenario=scenario and each.ind_health_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		
		//Heatmap values
		ask ccu_heatmap{grid_value <- 0.0;}
		 ask health_facilities{
		 	blocks the_block <- blocks where(each.from_scenario = scenario) closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}		
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2sports{
		
		//Radar values
		ask blocks where(each.from_scenario = scenario) inside (first(ccu_limit)){
			nb_different_sports_equipment <- 0;
			loop class over:sports_distances.keys{
				list<equipment> tmp_list <- sports_facilities where(each.subtype = class) at_distance(sports_distances[class]);
				nb_different_sports_equipment <- empty(tmp_list)?nb_different_sports_equipment:nb_different_sports_equipment+1;
			}
			ind_proximity_2_sports_equipment <- nb_different_sports_equipment > min_sports_equipment;
			float value_sum <- 0.0;
			ask people where(each.from_scenario = scenario and each.home_block=self){
				ind_sports_equipment_proximity <- myself.ind_proximity_2_sports_equipment;
				value_sum <- value_sum + (ind_sports_equipment_proximity?1:0);
			}
			int scenario_index <- scenario = 1?0:1;
			dash_public_spaces_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_sports_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		//write length(people where(each.from_scenario=scenario and each.ind_sports_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		
		//Heatmap values
		ask ccu_heatmap{grid_value <- 0.0;}
		 ask sports_facilities{
		 	blocks the_block <- blocks where(each.from_scenario = scenario) closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}		
		}
		do spread_value(spread_value_factor);
	}
	
	
	action heatmap2mobility{
		ask ccu_heatmap{grid_value <- 0.0;}
		ask blocks{
			list<people> my_people <- people where(each.home_block=self);
			mobility_access <- mean(my_people collect(each.mobility_accessibility));
		}
		ask diversity_grid{
			float value <- self.transportation_access;
			list<blocks> my_blocks <- blocks where(each.from_scenario = scenario) overlapping self;
			list<heatmap> the_cells;
			ask my_blocks{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{grid_value <- mean(my_blocks collect(each.mobility_access));}
			}
		}
		do spread_value(spread_value_factor);
	}
	
	//------------ HEATMAP SHOWS DIVERSITY
	action heatmap2daydiv{
		ask ccu_heatmap{grid_value <- 0.0;}
		ask div_grid where(each.from_scenario=scenario){
			ask heatmap inside(self){
				grid_value <- myself.day_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2nightdiv{
		ask ccu_heatmap{grid_value <- 0.0;}
		ask div_grid where(each.from_scenario=scenario){
			ask heatmap inside(self){
				grid_value <- myself.night_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2knowdiv{
		ask ccu_heatmap{grid_value <- 0.0;}
		ask div_grid where(each.from_scenario=scenario){
			ask heatmap inside(self){
				grid_value <- myself.knowledge_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	
	//-------------------------------------------
	//This function spread_value is a basic function to spread the grid value through the cells, causing the heatmap to appear smoother in the visualization.  
	action spread_value(int it){
		loop times:it{
			ask ccu_heatmap{
				list<heatmap> my_nb;
				heatmap tmp <- heatmap[grid_x+1,grid_y];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x+1,grid_y+1];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x,grid_y+1];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x-1,grid_y+1];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x-1,grid_y];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x-1,grid_y-1];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x,grid_y-1];
				if tmp != nil{add tmp to:my_nb;}
				tmp <- heatmap[grid_x+1,grid_y-1];
				if tmp != nil{add tmp to:my_nb;}
				grid_value <- grid_value*spread_factor + mean(my_nb  collect(each.grid_value))*(1-spread_factor);
				if grid_value < 0.25{grid_value <- grid_value * 1.20;}
				else if grid_value < 0.5{grid_value <- grid_value * 1.10;}
				else if grid_value < 0.75{grid_value <- grid_value * 1.05;}
			}
		}
		
	}
	//-----------------------------------------------------------------
	
}

//------------------ HEATMAP CELLS ------------------------------------------
grid heatmap width:world.shape.width/15 height:world.shape.height/15{
	rgb my_color <- rgb(0,0,0,0);
	float polution_value <- 0.0;
	bool valid <- true;
	aspect default{
		draw shape wireframe:true border:#red;
	}
	aspect heat{
		//draw shape color:rgb((1-grid_value)*255,grid_value*255,100,0.7);
		if show_heatmap{
			do update_color;
			float intensity <- grid_value=0?0.1:grid_value;
			intensity <- grid_value>0.65?0.65:grid_value;
			draw shape wireframe:false color:rgb(my_color,grid_value=1?1.2:intensity);// border:rgb(my_color,grid_value=0?0.1:intensity);
		}
		
	}
	action update_color{
		rgb result <- rgb(255,255,255);
		if(grid_value<0.20){
			result <- rgb(0,4*grid_value,result.blue,grid_value*1.2);
		}
		else if(grid_value<0.4){
			result <- rgb(0,result.green,4*(0.25-grid_value));
		}
		else if(grid_value<0.55){
			result <- rgb(4*(grid_value-0.5),result.green,0, grid_value*0.8);
		}
		else if(grid_value<0.7){
			result <- rgb (241, 216, 39,255);
			//result <- rgb(4*(grid_value-0.5),result.green,0, grid_value*0.8);
		}
		else if(grid_value<0.85){
			result <- rgb (248, 111, 18,255);
			//result <- rgb(4*(grid_value-0.5),result.green,0, grid_value*0.8);
		}
		else if(grid_value<0.9){
			result <- rgb (252, 105, 15,255);
		}
		else{
			result <- rgb(result.red,1+3*(0.75*grid_value),0,grid_value*0.7);
		}
		my_color <-  result;
	}
}

//------------------ SPECIES -----------------------------------------------------

// SPECIES THAT WERE ADDED IN THE VERSION 2**********
species project{
	
	string id;
	int from_scenario;
	string block_id;
	string project_name;
	int population;
	string use_type;
	int nb_ec_units; //Nb of economic units
	int UBS;
	float green_areas_m2;
	float building_m2;
	int VIV40M;
	int VIV60M;
	int VIV80M;
	list<economic_unit> my_new_activities;
	
	
	action create_new_population{
		blocks my_block <-first( blocks where(each.id=block_id));
		create people number:population returns:new_people;
		ask new_people{
			from_scenario <- myself.from_scenario;
			location <- any_location_in(my_block);
		}
	}
	
	//Function that computes the random activites that are coming with the project, using the data about the allowed activities for this project.
	action create_new_activities{
		my_new_activities <- [];
		//Check the permited land uses for the project. 
		list<string> allowed_activities_for_me <- allowed_activities[use_type];
		loop i over: sample(allowed_activities_for_me,nb_ec_units,true){
			create economic_unit with:[from_scenario::2,sub_id::i] returns:new_unit;
			economic_unit new_unit_ <- first(new_unit);
			blocks my_block <-first( blocks where(each.id=block_id));
			ask new_unit_{
				location <- any_location_in (my_block);
			}
			add first(new_unit) to:my_new_activities;
		}
	}
	
	action activate{
		do create_new_population;
		do create_new_activities;
	}
	action deactivate{
		ask people where(each.from_scenario=from_scenario){do die;}
		ask economic_unit where(each.from_scenario=from_scenario){do die;}
	}
	aspect default{
		draw shape wireframe:true border:#white;
	}
}

species economic_unit{
	int from_scenario;
	string activity_id;
	string sub_id;
	aspect default{
		draw circle(10);
	}
}

species intervention_area{
	int active_scenario;
	string area_name;
	string id;
	string associated_projects_str;
	list<project> associated_projects;
	action activate_scenario(int new_scenario){
		if active_scenario != new_scenario{
			ask associated_projects where(each.from_scenario=active_scenario){
				do deactivate;
			}
			ask associated_projects where(each.from_scenario=new_scenario){
				do activate;
			}
			active_scenario <- new_scenario;
		}
		
	}
	aspect default{
		draw shape wireframe:true border:#yellow;
	}
	aspect default{
		draw shape wireframe:true border:#yellow;
	}
}
//***********************************************************


species car skills:[moving]{
	int from_scenario;
	event_location my_event;
	reflex move_towards_event when:(from_scenario=4){
		if location = my_event.location{
			do die;
		}
		else{
			do goto target:my_event on:event_roads_network speed:0.05;
		}
	}
	aspect default{
		draw circle(5) color:#white;
	}
}

//Entry points
species entry_point{
	float rate <- 0.0;
}
species event_location{
	int capacity;
	int current_people <- 0;
}

//Species related to transportation
species transport_station{
	string type;
	string subtype;
	image_file my_icon <- image_file("../includes/img/bus.png") ;
	aspect default{
		draw my_icon size:40;
	}
}
species cycling_way{
	aspect default{
		draw shape color:#green width:2.0;
	}
}


//This diversity grid is used to initialize the diversity value. Once the simulation starts, the idea is to update such value from the scenario configuration.
species diversity_grid{
	int from_scenario;
	
	//Indicators
	float transportation_access;
	float night_diversity;
	float day_diversity;
	float knowledge_diversity;
	float social_interactions;
	
	reflex update_interactions when:show_interactions and flip(0.1){
		social_interactions <- min(1,(length(people where(each.from_scenario=self.from_scenario))/10));
		if show_interactions{
			ask ccu_heatmap where(each overlaps self){
					grid_value <- myself.social_interactions;
			}
		}
	}
	
	aspect default{
		draw shape border:#red color:rgb(200,20,20,day_diversity/max_diversity);
	}
}

species equipment{
	bool valid <- false;
	int from_scenario;
	string type;
	string subtype;
	
	aspect by_type{
		if type="Cultura"{color <- #green;}
		else if type="Salud"{color<- #blue;}
		else if type = "Educación"{color<-#cyan;}
		draw square(20) color: color;
	}
}
species ccu_limit{
	aspect default{	
		//draw satellite;
		draw shape wireframe:true border:#red ;
	}
}
species blocks{
	string id;
	int from_scenario;
	int nb_people;
	float block_area;
	bool valid <- false;
	
	//Indicators that are computed at block level
	float mobility_access;
	//Cultural equipment
	int nb_different_cultural_equipment <- 0;
	bool ind_proximity_2_cultural_equipment <- false;
	int nb_different_education_equipment <- 0;
	bool ind_proximity_2_education_equipment <- false;
	int nb_different_health_equipment <- 0;
	bool ind_proximity_2_health_equipment <- false;
	int nb_different_sports_equipment <- 0;
	bool ind_proximity_2_sports_equipment <- false;
	
	aspect default{
		if scenario=2 and from_scenario=2{
			draw shape color:rgb(100,100,100,0.2) border:#blue width:5.0;
		}
		else if scenario = 1 and from_scenario =1{
			draw shape color:rgb(100,100,100,0.2) border:#blue width:5.0;
		}
		//draw shape wireframe:false color:valid?#green:#red;// border:#blue;
	}
}

//This species represents the polygons that are going to be changed through the physical interface
/*species intervention_area{
	string letter;
	aspect default{
		if show_intervention_areas{
			draw shape color:#green border:#red width:5.0;
		}
	}
}*/

species roads{
	int from_scenario;
	aspect default{
		draw shape color:#gray;
	}
}

//This species is created to draw a background with the satellite image
species satellite_background{
	image_file satellite;
	init{
		satellite <- image_file("../includes/img/satellite_v2_bh.png");
	}
	aspect default{
		if show_satellite{
			draw shape border:#red texture:satellite;
		}
		
	}
}

species people skills:[moving]{
	
	//Related to individual indicators
	float mobility_accessibility <- 0.0;
	bool ind_public_transport_coverage			<- false;
	bool ind_cultural_equipment_proximity 		<- false;
	bool ind_education_equipment_proximity 	<- false;
	bool ind_health_equipment_proximity			<- false;
	bool ind_sports_equipment_proximity 		<- false;
	
	//Variables related to scenarios
	int from_scenario;
	
	//Related to mobility
	blocks home_block;
	blocks target_block;
	point target_point;
	path roads_path;
	list<point> my_path;
	int point_counter <- 0;
	string current_destinity <- "work" among:["home","work"];
	map<date,string> agenda_day;
	string mobility_type;

	//This action is to compute mobility_accessibility
	action compute_mobility_accessibility{
		int transport_accessibilty_count <- 0;
		list<float> distances <- [];
		transport_station closest_station <- transport_station where(each.type="bus") closest_to self;
		add closest_station distance_to self to:distances;
		closest_station <- transport_station where(each.type="massive" and each.subtype="BRT (Bus Rapid Transit)") closest_to self;
		add closest_station distance_to self to:distances;
		closest_station <- transport_station where(each.type="massive" and each.subtype="Tren Eléctrico") closest_to self;
		add closest_station distance_to self to:distances;
		cycling_way closest_cycling_way <- cycling_way closest_to self;
		add closest_station distance_to self to:distances;
		if distances[0] < 300{transport_accessibilty_count <- transport_accessibilty_count + 1;} 
		if distances[1] < 500{transport_accessibilty_count <- transport_accessibilty_count + 1;}
		if distances[2] < 800{transport_accessibilty_count <- transport_accessibilty_count + 1;}
		if distances[3] < 300{transport_accessibilty_count <- transport_accessibilty_count + 1;}
		mobility_accessibility <- transport_accessibilty_count /4;
		ind_public_transport_coverage <- transport_accessibilty_count >=3;
	}

	//This action is used to select the mobility type for this agent
	string select_mobility_mode{
		float sum <- 0.0;
		float selection <- rnd(100)/100;
		loop mode over:student_mobility_percentages.keys{
			if selection < student_mobility_percentages[mode] + sum{
				return mode;
			}
			sum <- sum + student_mobility_percentages[mode];
		}
		return one_of(student_mobility_percentages.keys);
	}

	//First, we obtain the path from the map
	action init_path{
		bool reverse <- false;
		path tmp_path <- paths[string(home_block)+string(target_block)];
		if tmp_path = nil{
			reverse <- true;
			tmp_path <- paths[string(target_block)+string(home_block)];
		}
		do build_path_as_a_list(tmp_path);
		if reverse{do reverse_path;}
	}
	
	//Then, we transform the path to a list of points (to be followed
	action build_path_as_a_list(path the_path){
		loop r over:list(the_path){
			loop p over:r.shape.points{
				add p to:my_path;
			}
		}
	}
	
	//This function aims to reverse the current list of points (path)	
	action reverse_path{
		list<point> new_path;
		loop i from:0 to: length(my_path)-1{
			add my_path[length(my_path)-1-i] to:new_path;
		}
	}
	
	action update_polution_values{
		heatmap my_cell <- heatmap closest_to self;
		
	}
	
	//This reflex controls the agent's activities to do during the day
	reflex update_agenda when: (every(#day)) {
		agenda_day <- [];
		point the_activity_location <- any_location_in(target_block);
		int activity_time <- rnd(2,12);
		int init_hour <- rnd(6,12);
		int init_minute <- rnd(0,59);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,init_hour,init_minute,0);
		agenda_day <+ (activity_date::"activity");
		activity_date <- activity_date + activity_time#hours;
		init_minute <- rnd(0,59);
		activity_date <- activity_date + init_minute#minutes;
		agenda_day <+ (activity_date::"home");
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])) {
		string current_activity <-agenda_day.values[0];
		target_point <- current_activity = "activity"?any_location_in(target_block):any_location_in(home_block);
		agenda_day>>first(agenda_day);
	}
	
	//This reflex controls the action of moving from point A to B
	reflex moving when:from_scenario = scenario{
		do goto target:target_point on:roads_network speed:0.1;
		
		//do follow path:roads_path;
	}
	
	
	aspect default{
		if scenario=1 and from_scenario=1{
			draw circle(4) border:#yellow color:rgb((1-mobility_accessibility)*255,mobility_accessibility*255,0,1.0);
		}
		if scenario=2 and from_scenario=2{
			draw circle(4) border:#yellow color:rgb((1-mobility_accessibility)*255,mobility_accessibility*255,0,1.0);
		}
		
	}
}
species grid_paths{
	aspect default{
		loop k over: paths.keys{
			loop p over:list(paths[k]){
				draw p.shape color:#red;
			}
			
		}
	}
}


//--------------------------   EXPERIMENTS DEFINITION --------------------------------------
experiment CCU_1_1000 type:gui{
	output{
		display gui fullscreen:0 type:opengl background:#black axes:false{
			 //BEST CALIBRATED CAMERAS
			
			// camera 'default' location: {1482.4217,1625.375,1913.8429} target: {1482.8714,1623.9457,0.0}; //ROTADA WORKING FIRST LIMITS
			
			 //camera 'default' location: {1480.8236,1625.2571,1913.8429} target: {1480.9663,1623.7635,0.0};
			 //camera 'default' location: {1482.5464,1627.3424,1913.8429} target: {1482.6891,1625.8508,0.0};
			//camera 'default' dynamic:true location: {1006.2548,657.1804,1679.7139} target: {1004.6164,667.1629,0.0};
			
			 //camera 'default' location: {1482.625,1625.4237,1913.8429} target: {1495.219,1673.9763,0.0};//ROTADA AJUSTADA
			 //camera 'default' location: {1482.7287,1625.4373,1913.8429} target: {1482.8714,1623.9457,0.0};
			
			
			 //camera 'default' location: {1028.7383,671.4495,1740.1146} target: {1028.7431,671.4195,0.0};//26 de abril
			 camera 'default' location: {1007.3931,681.2155,1668.1296} target: {1009.0202,671.3018,0.0};
			 
			overlay size:{0,0} position:{0.1,0.1} transparency:0.5{
				draw "abcdefghiíjklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 55, #bold);
				int the_day <- current_date.day-starting_date.day +1;
				string str_day <- int_to_day[the_day];
				string minute <- current_date.minute<10?(string(0)+current_date.minute):current_date.minute;
				draw str_day+" "+current_date.hour+":"+ minute at:{30#px,30#px} color:#white font: font("Arial", 55,#bold);
			}
			species satellite_background aspect:default refresh:true;
			species ccu_limit aspect:default refresh:true;
			species blocks aspect:default;
			species intervention_area aspect:default;
			species economic_unit aspect:default;
			species people aspect:default;
			species car aspect:default;
			species heatmap aspect:heat;
			
			//Keyboard events
			event a action:select_scenario_1;
			event b action:select_scenario_2;
			event h {show_heatmap <- !show_heatmap;} //Heatmap display
			event s action:heatmap2health;
			event e action:heatmap2education;
			event c action:heatmap2culture;
			event x action:heatmap2sports;
			event d action:heatmap2daydiv;
			event n action:heatmap2nightdiv;
			event w action:heatmap2knowdiv;
			event m action:heatmap2mobility;
			event p action:heatmap2polution;
		}
	}
}
