/**
* Name: CityScope.gaml
* CityScope Guadalajara, case study: University Cultural District
* Author: Gamaliel Palomo, Juan Alvarez, Arnaud Grignard
* Tags: 
*/

/*
 * HISTORY
 * gama-may04   Create history and add some changes to not allowing change the heatmap from mqtt messages (for now)
 * gama-issue14-may05	Remove the skill moving from people as now the moving agents are cars. People are just used to compute indicators
 * gama-issue13-may05 Clean the file names and directories.
 * gama-issue14-may08 Work on integration between Traffic model and CityScope. Now when a person needs to move due to the scheduler, it creates a car agent which makes de driving behavior.
 * gama-issue14-may10 People enters the zone via the entry points at an specific rate.
 */

model CityScope
import "constants.gaml"
import "Traffic_model.gaml"


global skills:[network]{
	
	//Shape files
	
	//Environmental shapes
	file dcu_limit_shp <- file(dcu_limits_filename);
	file dcu_satellite_shp <- file(main_shp_path+"environment/envolvente_mesa_imagen_satelital.shp");
	file ccu_limit_shp <- file(main_shp_path+"environment/scenario_limits.shp");
	file ccu_transport_shp <- file(main_shp_path+dcu_transport_filename);
	file ccu_massive_transport_shp <- file(main_shp_path+dcu_massive_transport_filename);
	file cycling_ways_shp <- file(dcu_cycling_way_filename);
	file intervention_areas_shp <- file(main_shp_path+intervention_areas_filename);
	file economic_activities_shp <- file(main_shp_path+economic_activities_filename);
	file projects_csv <- csv_file(main_csv_path+projects_csv_filename);
	file day_activities_csv <- csv_file(main_csv_path+day_activities_csv_filename);
	file night_activities_csv <- csv_file(main_csv_path+night_activities_csv_filename);
	file knowledge_activities_csv <- csv_file(main_csv_path+knowledge_activities_csv_filename);
	file interaction_places_csv <- csv_file(main_csv_path+interaction_places_csv_filename);
	file tertiary_activities_csv <- csv_file(main_csv_path+third_places_csv_filename);
	file projects_shp <- file(main_shp_path+projects_shp_filename);
	file allowed_activities_csv <- csv_file(main_csv_path+allowed_activities_by_use_filename);
	file green_areas_shp <- file(main_shp_path+green_areas_file);
	
	
	//Shapes for people flows in case of a cultural event
	file events_roads_shp <- file(events_roads_filename);
	file events_entry_points_shp <- file(events_entry_points_filename);
	file events_location_points_shp <- file(events_locations_filename);
	
	//Generic and unique list of elements
	list<blocks> current_active_blocks;
	list<household> current_active_households;
	
	//Scenario 1
	file s1_roads_shp 				<- file(main_shp_path+"scenario1/roads.shp");
	file s1_aux_roads_shp 		<- file(main_shp_path+"scenario1/aux_roads.shp");
	file s1_blocks_shp 				<- file(main_shp_path+"scenario1/blocks.shp");
	file s1_equipment_shp 		<- file(main_shp_path+"scenario1/equipment.shp");
	file s1_grid_shp 					<- file(main_shp_path+"scenario1/grid.shp");
	
	//Scenario 2
	file s2_roads_shp 				<- file(main_shp_path+"scenario2/roads.shp");
	file s2_aux_roads_shp 		<- file(main_shp_path+"scenario2/aux_roads.shp");
	file s2_blocks_shp 				<- file(main_shp_path+"scenario2/blocks.shp");
	file s2_grid_shp 					<- file(main_shp_path+"scenario2/grid.shp");
	
	//Simulation parameters
	geometry shape <- envelope(dcu_limit_shp);
	float incoming_people_rate <- 0.1 min:0.0 max:1.0 parameter:"Incoming people rate" category:"Functionality"; //gama-issue14-may10   Number of people per second that appears at each entry point
	bool telmex_event <- false parameter:"Telmex event" category:"Functionality";
	//int scenario <- 1;
	
	
	//Road network variables
	graph roads_network;
	graph event_roads_network;
	map<string,path> paths;
	map event_roads_weight;
	map roads_weight;
	
	//Network variables
	bool enable_mqtt <- false parameter:"Enable MQTT" category:"Functionality";
	string mqtt_server_name <- "localhost";
	string mqtt_topic <- "cityscope_table";
	
	
	//Visualization variables
	bool show_satellite <- false parameter:"Satellite" category:"Visualization";
	bool show_people <- true parameter:"People" category:"Visualization";
	bool show_information <- false parameter:"Information" category:"Visualization";
	
	//Heatmap  variables
	string current_heatmap 		<- "";
	bool show_heatmap 			<- false;
	list<heatmap> ccu_heatmap;
	
	//Indicators  variables
	list<equipment> education_facilities;
	list<equipment> culture_facilities;
	list<equipment> health_facilities;
	list<equipment> sports_facilities;
	list<base_grid> ref_grid;
	
	//Variables related to interventions
	map<string,list<string>> allowed_activities;
	list<string> day_activities;
	list<string> night_activities;
	list<string> interaction_places;
	list<string> knowledge_activities;
	list<string> tertiary_activities;
	map<string,int> current_scenarios;
	
	//Indicators variables that are going to be sent to the dashboard
	bool allow_export_data 				<- true;
	bool allow_export_data_sc2 			<- false;
	bool allow_export_current_data 	<- false;
	int 	 time_2_save_data				    <- 0;
	int	 time_2_update_heatmap 		<- 0;
	bool semaphore 							<- false;
	bool reset_counter							<- false;
	
	bool scenario_changed 				<- false;
	
	//All this indicators are initialized to 0 at each of the 3 scenarios.
	//DIVERSITY
	list<float> dash_day_activities_diversity 					<- [0.0,0.0,0.0];
	list<float> dash_night_activities_diversity 				<- [0.0,0.0,0.0];
	list<float> dash_third_activities_diversity 				<- [0.0,0.0,0.0];
	list<float> dash_knowledge_activities_diversity 			<- [0.0,0.0,0.0];
	list<float> dash_interaction_diversity 						<- [0.0,0.0,0.0];
	//FUNCTIONALITY
	list<float> dash_hab_net_density 							<- [0.0,0.0,0.0];
	list<float> dash_living_place_density 						<- [0.0,0.0,0.0];
	list<float> dash_day_density 								<- [0.0,0.0,0.0];
	list<float> dash_night_density 								<- [0.0,0.0,0.0];
	list<float> dash_knowledge_density							<- [0.0,0.0,0.0];
	list<float> dash_interaction_density						<- [0.0,0.0,0.0];
	list<float> dash_mean_activities_density					<- [0.0,0.0,0.0];
	list<float> dash_green_space_per_hab 							<- [0.0,0.0,0.0];
	list<float> dash_public_spaces_proximity 					<- [0.0,0.0,0.0];
	list<float> dash_educational_equipment_proximity 			<- [0.0,0.0,0.0];
	list<float> dash_cultural_equipment_proximity 				<- [0.0,0.0,0.0];
	list<float> dash_health_equipment_proximity 				<- [0.0,0.0,0.0];
	list<float> dash_social_assistance_equipment_proximity 		<- [0.0,0.0,0.0];
	list<float> dash_mean_facilities_proximity					<- [0.0,0.0,0.0];
	list<float> dash_intersections_density 						<- [0.0,0.0,0.0];
	list<float> dash_public_transport_coverage					<- [0.0,0.0,0.0];
	list<float>	dash_km_ways_per_hab							<- [0.0,0.0,0.0];
	list<float>	dash_km_ways_per_km2							<- [0.0,0.0,0.0];
	//ENVIRONMENTAL IMPACT
	list<float> dash_energy_requirement 	<- [0.0,0.0,0.0];
	list<float> dash_water_requirement 		<- [0.0,0.0,0.0];
	list<float> dash_waste_generation 		<- [0.0,0.0,0.0];
	
	//Visualization variables
	map<int,string> int_to_day <- [1::"Jueves",2::"Viernes",3::"Sábado",4::"Domingo",5::"Lunes",6::"Martes",7::"Miércoles"];

	
	init{
		
		//Simulation specific variables
		step 					<- 2#seconds;
		starting_date 	<- date("2023-05-16 07:00:00");
		
		//Initialize MQTT connection
		if (enable_mqtt){
			write "Initializing MQTT connection";
			do connect to:"localhost" with_name:"cityscope_table";
		}
		
		//Create environment agents
		//create ccu_limit from:ccu_limit_shp;
		create ccu_limit from: dcu_limit_shp;
		create transport_station from: ccu_transport_shp with:[type::"bus"];
		create transport_station from: ccu_massive_transport_shp with:[type::"massive",subtype::string(read("Sistema"))];
		create cycling_way from:cycling_ways_shp;
		
		
		//-----------   Create environment agents from scenario 1
		//gama-issue14-may05 Deleted create roads, and roads_netwok as they are not used anymore.
		create blocks from:s1_blocks_shp with:[id::read("ID_BLOCK"),from_scenario::1,nb_people::int(read("POB1")),block_area::float(read("area_m2")),viv_type::read("TIPO_VIVIE"), nb_households::int(read("VIVTOTAL"))]{
			create people number:int(nb_people/nb_people_prop) with:[home_block::self,target_block::one_of(blocks-self)]{
				from_scenario <- 1;
				home_point <- any_location_in(home_block);
				location <- home_point;
				mobility_type <- select_mobility_mode();
			}
			create household number:nb_households with:[location::any_location_in(self),from_scenario::1] returns:tmp_my_households;
			if tmp_my_households != nil{
				ask tmp_my_households{
					add self to:myself.my_households;
				}
				tmp_my_households <- [];
			}
		}
		
		current_active_blocks <- list(blocks);
		
		create economic_unit from:economic_activities_shp with:[from_scenario::1,activity_id::read("codigo_act"),sub_id::read("sec_sub")];
		create equipment from:s1_equipment_shp with:[type::string(read("tipo_equip")),subtype::string(read("cat_sedeso")),from_scenario::1];
		create green_area from:green_areas_shp with:[surface_area::float(read("area_m2"))];
		create base_grid from:s1_grid_shp with:[night_diversity::float(read("ID_NOCHE")),day_diversity::float(read("ID_DIA")),knowledge_diversity::float(read("ID_CONOCIM")),from_scenario::1];
		
		//-----------   Create environment agents from scenario B
		create blocks from:s2_blocks_shp with:[id::read("ID_BLOCK"),from_scenario::2,nb_people::int(read("POB1")),block_area::float(read("area_m2"))]{
			block_area <- block_area * 10000; //This conversion needs to bee eliminated
			nb_households <- int(nb_people / mean_family_size);
			create household number:nb_households with:[location::any_location_in(self),from_scenario::2] returns:tmp_my_households;
			if tmp_my_households != nil{
				ask tmp_my_households{
					add self to:myself.my_households;
				}
				tmp_my_households <- [];				
			}

		}
		
		list<household> raw_current_active_households <- list(household);
		//create base_grid from:s2_grid_shp with:[night_diversity::float(read("ID_NOCHE")),day_diversity::float(read("ID_DIA")),knowledge_diversity::float(read("ID_CONOCIM")),from_scenario::2];
		
		//------------ Create environment agents from scenario Event
		// gama-issue14-may05 Deleted the creation of event_network as the road network is going to be initiated by the mobility model
		create cultural_event from:events_location_points_shp with:[capacity::int(read("avg_asiste"))];
		create entry_point from:events_entry_points_shp;
		
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
		//Initialize lists of temporal activities
		data <- matrix(day_activities_csv);
		loop i from:1 to:data.rows-1{
			add data[0,i] to:day_activities;
		}
		data <- matrix(night_activities_csv);
		loop i from:1 to:data.rows-1{
			add data[0,i] to:night_activities;
		}
		data <- matrix(interaction_places_csv);
		loop i from:1 to:data.rows-1{
			add data[0,i] to:interaction_places;
		}
		data <- matrix(knowledge_activities_csv);
		loop i from:1 to:data.rows-1{
			add data[0,i] to:knowledge_activities;
		}
		data <- matrix(tertiary_activities_csv);
		loop i from:1 to:data.rows-1{
			add data[0,i] to:tertiary_activities;
		}
		
		//Create project agent from csv
		data <- matrix(projects_csv);
		loop i from: 0 to: data.rows -1{
			create project with:[
				block_id::data[0,i],
				id::data[1,i], 
				letter::data[2,i],
				project_name::data[3,i],
				use_type::data[6,i],
				from_scenario::2,
				population::int(data[8,i]),
				nb_ec_units::int(data[12,i]),
				viv_eco::int(data[9,i]),
				viv_med::int(data[10,i]),
				viv_res::int(data[11,i]),
				green_area::int(data[12,i])
			]{
				blocks the_block <- first(blocks where(each.from_scenario=2 and each.id = block_id));
				ask the_block{
					viv_eco <- myself.viv_eco;
					viv_med <- myself.viv_med;
					viv_res <- myself.viv_res;
				}
			}
		}	
		
		//Create intervention areas
		create intervention_area from:intervention_areas_shp with:[active_scenario::1,id::read("fid"),area_name::read("nombre"),associated_projects_str::read("id_ccu"), blocksS1_str::read("ID_BLOCK_E"),blocksS2_str::read("ID_BLOCK_1"),blocksS3_str::read("ID_BLOCK_2")]{
			//First, add the current intervention_area name to the map
			add self.area_name::1 to:current_scenarios;
			//Lets associate each area to a project in the projects data base created just before
			list<string> valid_project_ids <- project collect(each.id);
			if associated_projects != nil{
				list<string> str_projects <- split_with(associated_projects_str,",");
				if not empty(str_projects){
					loop p_id over: str_projects{
						if p_id in valid_project_ids{add first(project where(each.id=p_id)) to:associated_projects;}
					}
				}
			}
			list<string> valid_block_ids <- blocks collect(each.id);
			if blocksS1_str != nil{
				list<string> tmp <- split_with(blocksS1_str,",");
				if not empty(tmp){
					loop b_id over: tmp{
						if b_id in valid_block_ids{add first(blocks where(each.id=b_id and each.from_scenario=1) ) to:blocks_by_scenario[0];}
					}
				}
			}
			if blocksS2_str != nil{
				list<string> tmp <- split_with(blocksS2_str,",");
				if not empty(tmp){
					loop b_id over: tmp{
						if b_id in valid_block_ids{add first(blocks where(each.id=b_id and each.from_scenario=2)) to:blocks_by_scenario[1];}
					}
				}
			}
			if blocksS3_str != nil{
				list<string> tmp <- split_with(blocksS3_str,",");
				if not empty(tmp){
					loop b_id over: tmp{
						if b_id in valid_block_ids{add first(blocks where(each.id=b_id and each.from_scenario=2)) to:blocks_by_scenario[2];}
					}
				}
			}
			
		}	
		
		
		
		//Clean memory
		ccu_limit_shp 				<- [];
		s1_roads_shp 				<- [];
		s1_aux_roads_shp 		<- [];
		s2_aux_roads_shp 		<- [];
		s1_blocks_shp 				<- [];
		s1_equipment_shp 			<-[];
		s1_grid_shp 				<- [];
		s2_roads_shp 				<- [];
		s2_blocks_shp 				<- [];
		s2_grid_shp 				<- [];
		green_areas_shp 			<- [];
		ccu_transport_shp 			<- [];
		ccu_massive_transport_shp 	<- [];
		dcu_satellite_shp 			<- [];
		cycling_ways_shp 			<- [];
		intervention_areas_shp 		<- [];
		projects_shp 				<- [];
		events_roads_shp 			<- [];
		events_entry_points_shp 	<- [];
		events_location_points_shp 	<- [];
		data <- nil;
		
		
		education_facilities 	<- equipment where(each.type="Educación");
		culture_facilities 		<- equipment where(each.type="Cultura");
		health_facilities 			<- equipment where(each.type="Salud");
		sports_facilities			<- equipment where(each.type="Deporte");
		
		list<people>valid_people;
		list<car> valid_cars;
		list<economic_unit> valid_unit;
		ask ccu_limit{
			ccu_heatmap 				<- heatmap inside(self+50);
			ref_grid					<- base_grid inside(self +100);
			valid_people <- people inside self;
			valid_cars <- car inside self;
			valid_unit <- economic_unit inside self;
			current_active_households <- raw_current_active_households inside self;
		}
		ask people{
			if not (self in valid_people){to_be_killed <- true;}
		}
		/*ask economic_unit{
			if not(self in valid_unit){do die;}
		}*/
		ask heatmap{
			if not(self in ccu_heatmap){do die;}
		}
		ask household{
			if not(self in current_active_households){do die;}
		}
		current_active_households <- household where(each.from_scenario = 1);

		//TEST
		//write "hab/emp: "+hab_emp_ratio();
		
	}

	reflex update_hab_emp when:scenario_changed and false{
		write "hab/emp: "+hab_emp_ratio();
		scenario_changed <- false;
	}
	
	//Thos reflex is written to update the heatmap if a change in the table is detected
	reflex update_current_heatmap when:scenario_changed and show_heatmap{
		if time_2_update_heatmap >0{
			time_2_update_heatmap <- time_2_update_heatmap - 1;
		}
		else{
			switch current_heatmap{
				match "health" {do heatmap2health;}
				match "culture"{do heatmap2culture;}
				match "education"{do heatmap2education;}
				match "sports"{do heatmap2sports;}
				match "day_diversity"{do heatmap2daydiv;}
				match "night_diversity"{do heatmap2nightdiv;}
				match "knowledge_diversity"{do heatmap2knowdiv;}
				match "day_density"{do heatmap2daydensity;}
				match "night_density"{do heatmap2nightdensity;}
				match "knowledge_density"{do heatmap2knowledgedensity;}
				match "interaction_density"{do heatmap2interactiondensity;}
				match "population_density"{do heatmap2populationdensity;}
				match "mobility" {do heatmap2mobility;}
			}
			scenario_changed <- false;
		}
	}
	
	//Reflex to listen to the MQTT topic
	reflex readMailBox when:has_more_message() and enable_mqtt{
		message the_message <- fetch_message();
		write "Received: "+the_message.contents;
		// A, B, I, K, L
		string new_string <- the_message.contents;
		list<string> words <-split_with(new_string,",");
		loop w over: words{
			list<string> letters <- split_with(w,"/");
			if letters[0] ="M"{ //The message indicates the heatmap to activate
				write "Heatmap changes from MQTT not allowed";
				/*if(current_heatmap!=letters[1]){									//gama-may04-> We are not currently allowing changes to heatmap from MQTT
					write "Changing heatmap to "+letters[1];
					string opt <- letters[1];
					switch opt{
						match "health" {do heatmap2health();}
						match "education" {do heatmap2education();}
						match "culture" {do heatmap2culture();}
						match "sports" {do heatmap2sports();}
						match "daydiv" {do heatmap2daydiv();}
						match "nightdiv" {do heatmap2nightdiv();}
						match "knowdiv" {do heatmap2knowdiv();}
						match "daydensity" {do heatmap2daydensity();}
						match "nightdensity" {do heatmap2nightdensity();}
						match "knowledgedensity" {do heatmap2knowledgedensity();}
						match "nightdiv" {do heatmap2nightdiv();}
						match "interactiondensity" {do heatmap2interactiondensity();}
						match "populationdensity" {do heatmap2populationdensity();}
						match "householddensity" {do heatmap2householddensity();}
						match "mobility" {do heatmap2mobility();}
					}
				}
				else{
					write "Heatmap is already showing "+letters[1];
				}
				*/ 																	//<- gama-may04
			}
			else if letters[0] = "S"{//The message indicates to activate a full scenario
				string opt <- letters[1];
				switch opt{
					match "Current"{do activate_scenario1();}
					match "MasterPlan"{do activate_scenario2();}
				}
			}
			else{
				if letters[0]!="Z"{															//gama-may04-> Z means invalid polygon
					write "Activating polygon: "+letters[0]+", scenario: "+letters[1];
					current_scenarios[letters[0]] <- int(letters[1]);
					ask intervention_area where(each.area_name=letters[0]){
						do activate_scenario(int(letters[1]));
					}
				}																			//<-gama-may04
			}			
		}
		//allow_export_current_data <- true;
	}
	
	reflex incoming_people when:every(10#second){																															//gama-issue14-may10->
		ask entry_point{
			if flip(incoming_people_rate){
				create car number:5{
					source_sc <- "incoming";																																				
					target_block <- one_of(blocks);
					max_speed <- 40 #km / #h;
					vehicle_length <- 4.0 #m;
					right_side_driving <- true;
					proba_lane_change_up <- 0.1 + (rnd(500) / 500);
					proba_lane_change_down <- 0.5 + (rnd(500) / 500);
					location <- (intersection where empty(each.stop) closest_to myself).location;
					security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
					proba_respect_priorities <- 1.0 - rnd(200 / 1000);
					proba_respect_stops <- [1.0];
					proba_block_node <- 0.0;
					proba_use_linked_road <- 0.0;
					max_acceleration <- 5 / 3.6;
					speed_coeff <- 1.2 - (rnd(400) / 1000);
					threshold_stucked <- int((1 + rnd(5)) #mn);
					proba_breakdown <- 0.00001;
				}	
			}
		}
	}				
	
	reflex cultural_event_people when:telmex_event{
		ask entry_point{
			if flip(incoming_people_rate){
				create car number:5{
					source_sc <- "cultural event";																																				
					target_block <- one_of(blocks);
					max_speed <- 40 #km / #h;
					vehicle_length <- 4.0 #m;
					right_side_driving <- true;
					proba_lane_change_up <- 0.1 + (rnd(500) / 500);
					proba_lane_change_down <- 0.5 + (rnd(500) / 500);
					location <- (intersection where empty(each.stop) closest_to myself).location;
					security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
					proba_respect_priorities <- 1.0 - rnd(200 / 1000);
					proba_respect_stops <- [1.0];
					proba_block_node <- 0.0;
					proba_use_linked_road <- 0.0;
					max_acceleration <- 5 / 3.6;
					speed_coeff <- 1.2 - (rnd(400) / 1000);
					threshold_stucked <- int((1 + rnd(5)) #mn);
					proba_breakdown <- 0.00001;
				}	
			}
		}
	}																																														//<-gama-issue14-may10
	
	action activate_scenario1{
		reset_counter <- true;
		ask intervention_area {
			do activate_scenario(1);
		}
	}
	action activate_scenario2{
		reset_counter <- true;
		ask intervention_area {
			do activate_scenario(2);
		}
		//allow_export_current_data <- true;
	}
	action change_scenario_A{
		ask intervention_area where(each.area_name="A"){
			int tmp_sc <- self.active_scenario;
			if tmp_sc=3{
				tmp_sc <- 0;
			}
			tmp_sc <- tmp_sc + 1;
			do activate_scenario(tmp_sc);
		}
		allow_export_current_data <- true;
	}
	action change_scenario_B{
		ask intervention_area where(each.area_name="B"){
			int tmp_sc <- self.active_scenario;
			if tmp_sc=3{
				tmp_sc <- 0;
			}
			tmp_sc <- tmp_sc + 1;
			do activate_scenario(tmp_sc);
		}
		allow_export_current_data <- true;
	}
	action change_scenario_K{
		ask intervention_area where(each.area_name="K"){
			int tmp_sc <- self.active_scenario;
			if tmp_sc=3{
				tmp_sc <- 0;
			}
			tmp_sc <- tmp_sc + 1;
			do activate_scenario(tmp_sc);
		}
		allow_export_current_data <- true;
	}
	action change_scenario_L{
		ask intervention_area where(each.area_name="L"){
			int tmp_sc <- self.active_scenario;
			if tmp_sc=3{
				tmp_sc <- 0;
			}
			tmp_sc <- tmp_sc + 1;
			do activate_scenario(tmp_sc);
		}
		allow_export_current_data <- true;
	}
	action change_scenario_I{
		ask intervention_area where(each.area_name="I"){
			int tmp_sc <- self.active_scenario;
			if tmp_sc=3{
				tmp_sc <- 0;
			}
			tmp_sc <- tmp_sc + 1;
			do activate_scenario(tmp_sc);
		}
		allow_export_current_data <- true;
	}
	//This reflex is to produce cars flows for the mobility simulation
	/*reflex generate_car_flows when:sum(event_location collect(each.capacity - each.current_people))>0{
		ask entry_point{
			 
			if flip(self.rate/100){
				event_location tmp_location <- first(event_location where((each.capacity-each.current_people)>0));
				create car with:[from_scenario::4, my_event::tmp_location, location::self.location];
				ask tmp_location{current_people <- current_people - 1;}
			}
			
		}
	}*/
	
	reflex export_data_sc1 when:cycle=1 and allow_export_data{
		write "Saving data scenario 1";
		do heatmap2education;
		do heatmap2culture;
		do heatmap2health;
		//Scenario 1
		dash_day_activities_diversity[0] <- mean_diversity_day()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.day_diversity));
		dash_night_activities_diversity[0] <- mean_diversity_night()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.night_diversity));
		dash_knowledge_activities_diversity[0] <- mean_diversity_knowledge()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.knowledge_diversity));
		dash_interaction_diversity[0] <- mean_diversity_interaction()/max_diversity;
		dash_hab_net_density[0] <- mean_population_density()/max_density;
		dash_public_transport_coverage[0] <- (length(people where(each.ind_public_transport_coverage))/length(people))*100;
		dash_energy_requirement[0] <- mean_energy_requirement()/max_energy_requirement;
		dash_waste_generation[0] <- mean_waste_generation()/max_waste_generation;
		dash_water_requirement[0] <- mean_water_requirement()/max_water_requirement;
		dash_km_ways_per_hab[0] <- km_roads_per_person(1)/max_km_per_person;
		dash_km_ways_per_km2[0] <- km_roads_per_km2(1)/max_km_per_km2;
		dash_green_space_per_hab[0] <- ((sum(green_area collect(each.surface_area))/sum(current_active_blocks collect(each.nb_people))))/max_green_area_per_person;
		dash_educational_equipment_proximity[0] <- length(people where(each.ind_education_equipment_proximity))/length(people);
		dash_cultural_equipment_proximity[0] <- length(people where(each.ind_cultural_equipment_proximity))/length(people);
		dash_health_equipment_proximity[0] <- length(people where(each.ind_health_equipment_proximity))/length(people);
		dash_mean_facilities_proximity[0] <- mean(dash_educational_equipment_proximity[0],dash_cultural_equipment_proximity[0],dash_health_equipment_proximity[0]);
		dash_day_density[0] <- mean_density_day();
		dash_night_density[0] <- mean_density_night();
		dash_knowledge_density[0] <- mean_density_knowledge();
		dash_interaction_density[0] <- mean_density_interactions();
		dash_mean_activities_density[0] <- mean([dash_day_density[0],dash_night_density[0],dash_knowledge_density[0],dash_interaction_density[0]]);
		save data:[
			dash_night_activities_diversity[0],
			dash_interaction_diversity[0],
			dash_knowledge_activities_diversity[0],
			dash_energy_requirement[0],
			dash_water_requirement[0],
			dash_waste_generation[0],
			dash_green_space_per_hab[0],
			dash_km_ways_per_hab[0],
			dash_public_transport_coverage[0],
			dash_mean_facilities_proximity[0],
			dash_mean_activities_density[0],
			dash_hab_net_density[0],
			dash_hab_net_density[0],
			dash_day_activities_diversity[0]
		] to:"../output/output_s1.csv" format:"csv" rewrite:false;
	}
	reflex export_data_sc2 when:allow_export_data_sc2{
		//Scenario 2
		/*do heatmap2education;
		do heatmap2culture;
		do heatmap2health;
		do mean_density_day;
		do mean_density_night;
		do mean_density_knowledge;
		do mean_density_interactions;*/
		dash_day_activities_diversity[1] <- mean_diversity_day()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.day_diversity));
		dash_night_activities_diversity[1] <- mean_diversity_night()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.night_diversity));
		dash_knowledge_activities_diversity[1] <- mean_diversity_knowledge()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.knowledge_diversity));
		dash_interaction_diversity[1] <- mean_diversity_interaction()/max_diversity;
		dash_hab_net_density[1] <- mean_population_density()/max_density;
		dash_public_transport_coverage[1] <- (length(people where(each.ind_public_transport_coverage))/length(people))*100;
		dash_energy_requirement[1] <- mean_energy_requirement()/max_energy_requirement;
		dash_waste_generation[1] <- mean_waste_generation()/max_waste_generation;
		dash_water_requirement[1] <- mean_water_requirement()/max_water_requirement;
		dash_km_ways_per_hab[1] <- km_roads_per_person(2)/max_km_per_person;
		dash_km_ways_per_km2[1] <- km_roads_per_km2(2)/max_km_per_km2;
		dash_green_space_per_hab[1] <- ((sum(green_area collect(each.surface_area))/sum(blocks where(each.from_scenario=1) collect(each.nb_people))))/max_green_area_per_person;
		dash_educational_equipment_proximity[1] <- length(people where(each.ind_education_equipment_proximity))/length(people);
		dash_cultural_equipment_proximity[1] <- length(people where(each.ind_cultural_equipment_proximity))/length(people);
		dash_health_equipment_proximity[1] <- length(people where(each.ind_health_equipment_proximity))/length(people);
		dash_mean_facilities_proximity[1] <- mean(dash_educational_equipment_proximity[1],dash_cultural_equipment_proximity[1],dash_health_equipment_proximity[1]);
		dash_day_density[1] <- mean_density_day();
		dash_night_density[1] <- mean_density_night();
		dash_knowledge_density[1] <- mean_density_knowledge();
		dash_interaction_density[1] <- mean_density_interactions();
		dash_mean_activities_density[1] <- mean([dash_day_density[1],dash_night_density[1],dash_knowledge_density[1],dash_interaction_density[1]]);
		save data:[
			dash_night_activities_diversity[1],
			dash_interaction_diversity[1],
			dash_knowledge_activities_diversity[1],
			dash_energy_requirement[1],
			dash_water_requirement[1],
			dash_waste_generation[1],
			dash_green_space_per_hab[1],
			dash_km_ways_per_hab[1],
			dash_public_transport_coverage[1],
			dash_mean_facilities_proximity[1],
			dash_mean_activities_density[1],
			dash_hab_net_density[1],
			dash_hab_net_density[1],
			dash_day_activities_diversity[1]
		] to:"../output/output_s2.csv" format:"csv" rewrite:true;
		allow_export_data_sc2 <- false;
	}
	reflex compute_current_data when:allow_export_current_data{
		write "Remaining time: "+time_2_save_data;
		if time_2_save_data > 0{
			time_2_save_data <- time_2_save_data - 1;
		}
		else{
			write "Saving data active scenario";
			//Active scenario
			dash_day_activities_diversity[2] <- mean_diversity_day()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.day_diversity));
			dash_night_activities_diversity[2] <- mean_diversity_night()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.night_diversity));
			dash_knowledge_activities_diversity[2] <- mean_diversity_knowledge()/max_diversity;//mean(ref_grid where(each.from_scenario=1) collect(each.knowledge_diversity));
			dash_interaction_diversity[2] <- mean_diversity_interaction()/max_diversity;
			dash_hab_net_density[2] <- mean_population_density()/max_density;
			dash_public_transport_coverage[2] <- (length(people where(each.ind_public_transport_coverage))/length(people))*100;
			dash_energy_requirement[2] <- mean_energy_requirement()/max_energy_requirement;
			dash_waste_generation[2] <- mean_waste_generation()/max_waste_generation;
			dash_water_requirement[2] <- mean_water_requirement()/max_water_requirement;
			dash_km_ways_per_hab[2] <- km_roads_per_person(2)/max_km_per_person;
			dash_km_ways_per_km2[2] <- km_roads_per_km2(2)/max_km_per_km2;
			dash_green_space_per_hab[2] <- ((sum(green_area collect(each.surface_area))/sum(current_active_blocks collect(each.nb_people))))/max_green_area_per_person;
			dash_educational_equipment_proximity[2] <- mean_education_proximity();
			dash_cultural_equipment_proximity[2] <- mean_culture_proximity();
			dash_health_equipment_proximity[2] <- mean_health_proximity();
			dash_mean_facilities_proximity[2] <- mean(dash_educational_equipment_proximity[2],dash_cultural_equipment_proximity[2],dash_health_equipment_proximity[2]);
			dash_day_density[2] <- mean_density_day();
			dash_night_density[2] <- mean_density_night();
			dash_knowledge_density[2] <- mean_density_knowledge();
			dash_interaction_density[2] <- mean_density_interactions();
			dash_mean_activities_density[2] <- mean([dash_day_density[2],dash_night_density[2],dash_knowledge_density[2],dash_interaction_density[2]]);
			save data:[
				dash_night_activities_diversity[2],
				dash_interaction_diversity[2],
				dash_knowledge_activities_diversity[2],
				dash_energy_requirement[2],
				dash_water_requirement[2],
				dash_waste_generation[2],
				dash_green_space_per_hab[2],
				dash_km_ways_per_hab[2],
				dash_public_transport_coverage[2],
				dash_mean_facilities_proximity[2],
				dash_mean_activities_density[2],
				dash_hab_net_density[2],
				dash_hab_net_density[2],
				dash_day_activities_diversity[2],
				1
			] to:"../output/output_radar_active.csv" format:"csv" rewrite:true header:false;
			
			save data:[
				dash_educational_equipment_proximity[2],
				dash_health_equipment_proximity[2],
				dash_cultural_equipment_proximity[2],
				dash_cultural_equipment_proximity[2],
				dash_cultural_equipment_proximity[2],
				1
			] to:"../output/output_facilities_proximity_active.csv" format:"csv" rewrite:true header:false;
			
			save data:[
				
				dash_day_density[2],
				dash_night_density[2],
				dash_interaction_density[2],
				dash_knowledge_density[2],
				1
			] to:"../output/output_activities_density_active.csv" format:"csv" rewrite:true header:false;
			
			save data:[
				dash_km_ways_per_km2[2],
				dash_day_activities_diversity[2],
				dash_km_ways_per_km2[2],
				dash_day_activities_diversity[2],
				1
			] to:"../output/output_walkability_active.csv" format:"csv" rewrite:true header:false;
			allow_export_current_data<- false;
		}
	}
		
	
	action activate_scenario1{
		ask intervention_area{
			do activate_scenario(1);
		}
	}
	action activate_scenario2{
		ask intervention_area{
			do activate_scenario(2);
		}
	}
	
	//gama-issue14-may05 Deleted function path_finder as it is not needed
	
	action show_satellite_action{
		show_satellite <- !show_satellite;
	}
	
	float mean_education_proximity{
		float result;
		int people_with_access <- 0;
		ask current_active_blocks inside (first(ccu_limit+1000)){
			nb_different_education_equipment <- 0;
			loop class over:education_distances.keys{
				list<equipment> tmp_list <- education_facilities where(each.subtype = class) at_distance(education_distances[class]);
				nb_different_education_equipment <- empty(tmp_list)?nb_different_education_equipment:nb_different_education_equipment+1;
			}
			ind_proximity_2_education_equipment <- nb_different_education_equipment > min_education_equipment;
			people_with_access <- people_with_access + (ind_proximity_2_education_equipment?self.nb_people:0);
			//int scenario_index <- scenario = 1?0:1;
			//dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		return people_with_access/sum(current_active_blocks collect(each.nb_people));
	}
	
	float mean_culture_proximity{
		float result;
		int people_with_access <- 0;
		ask current_active_blocks inside (first(ccu_limit+1000)){
			nb_different_cultural_equipment <- 0;
			loop class over:culture_distances.keys{
				list<equipment> tmp_list <- culture_facilities where(each.subtype = class) at_distance(culture_distances[class]);
				nb_different_cultural_equipment <- empty(tmp_list)?nb_different_cultural_equipment:nb_different_cultural_equipment+1;
			}
			ind_proximity_2_cultural_equipment <- nb_different_cultural_equipment > min_culture_equipment;
			people_with_access <- people_with_access + (ind_proximity_2_cultural_equipment?self.nb_people:0);
			//int scenario_index <- scenario = 1?0:1;
			//dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		return people_with_access/sum(current_active_blocks collect(each.nb_people));
	}
	
	float mean_health_proximity{
		float result;
		int people_with_access <- 0;
		ask current_active_blocks inside (first(ccu_limit+1000)){
			nb_different_health_equipment <- 0;
			loop class over:health_distances.keys{
				list<equipment> tmp_list <- health_facilities where(each.subtype = class) at_distance(health_distances[class]);
				nb_different_health_equipment <- empty(tmp_list)?nb_different_health_equipment:nb_different_health_equipment+1;
			}
			ind_proximity_2_health_equipment <- nb_different_health_equipment > min_health_equipment;
			people_with_access <- people_with_access + (ind_proximity_2_health_equipment?self.nb_people:0);
			//int scenario_index <- scenario = 1?0:1;
			//dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		return people_with_access/sum(current_active_blocks collect(each.nb_people));
	}
	
	float mean_sports_proximity{
		float result;
		int people_with_access <- 0;
		ask current_active_blocks inside (first(ccu_limit+1000)){
			nb_different_sports_equipment <- 0;
			loop class over:health_distances.keys{
				list<equipment> tmp_list <- sports_facilities where(each.subtype = class) at_distance(sports_distances[class]);
				nb_different_sports_equipment <- empty(tmp_list)?nb_different_sports_equipment:nb_different_sports_equipment+1;
			}
			ind_proximity_2_sports_equipment <- nb_different_sports_equipment > min_sports_equipment;
			people_with_access <- people_with_access + (ind_proximity_2_sports_equipment?self.nb_people:0);
			//int scenario_index <- scenario = 1?0:1;
			//dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		return people_with_access/sum(current_active_blocks collect(each.nb_people));
	}
	
	float mean_energy_requirement{
		float result;
		ask current_active_blocks{
			do compute_energy_requirement;
		}
		result <- mean(current_active_blocks where(each.energy_requirement>0) collect(each.energy_requirement));
		write result;
		return result;
	}
	float mean_waste_generation{
		float result;
		ask current_active_blocks{
			do compute_waste_generation;
		}
		result <- mean(current_active_blocks where(each.waste_generation>0) collect(each.waste_generation));
		write result;
		return result;
	}
	float mean_water_requirement{
		float result;
		ask current_active_blocks{
			do compute_water_requirement;
		}
		result <- mean(current_active_blocks where(each.water_requirement>0) collect(each.water_requirement));
		write result;
		return result;
	}
	
	float mean_population_density{
		float result;
		/*ask current_active_blocks{
			do compute_population_density;
		}*/
		float total_blocks_area <- sum(current_active_blocks collect(each.block_area));
		total_blocks_area <- total_blocks_area * 0.0001;
		int total_population <- sum(current_active_blocks collect(each.nb_people));
		result <- total_population/total_blocks_area;//mean(current_active_blocks where(each.population_density>0) collect(each.population_density));
		return result;
	}
	float mean_household_density{
		float result;
		float total_blocks_area <- sum(current_active_blocks collect(each.block_area));
		total_blocks_area <- total_blocks_area * 0.0001;
		int total_household <- sum(current_active_blocks collect(each.nb_households));
		//result <- total_household/total_blocks_area;
		return result;
	}
	float km_roads_per_person(int sc){
		float result;
		//result <- roads_km[sc]/(sum(current_active_blocks collect(each.nb_people))/100);
		float total_length <- sum(aux_roads where(each.from_scenario = sc) collect(each.length));
		write "roads: "+length(aux_roads where(each.from_scenario = sc));
		result <- sum(aux_roads where(each.from_scenario = sc) collect(each.length))/sum(current_active_blocks collect(each.nb_people));
		return result;
	}
	float km_roads_per_km2(int sc){
		float result;
		float dcu_km2 <- dcu_area_ha * 0.01;
		//result <- roads_km[sc]/dcu_area_ha;
		result <- sum(aux_roads where(each.from_scenario = sc) collect(each.length))/dcu_area_ha;
		return result;
	}
	
	float mean_activities_diversity{
		
		float result;
		write length(base_grid);
		ask base_grid{
			list<int> class_counter <- [0,0,0,0,0];
			list<economic_unit> my_activities <- economic_unit inside(self);
			write my_activities;
			if not empty(my_activities){
				loop act over:my_activities{
					if act.sub_id in day_activities{class_counter[0]<-class_counter[0]+1;}
					else if act.sub_id in night_activities{class_counter[1]<-class_counter[1]+1;}
					else if act.sub_id in knowledge_activities{class_counter[2]<-class_counter[2]+1;}
					else if act.sub_id in interaction_places{class_counter[3]<-class_counter[3]+1;}
					else if act.sub_id in tertiary_activities{class_counter[4]<-class_counter[4]+1;}
				}
				write class_counter;
			}
			int total_activities <- sum(class_counter);
			write total_activities;
			
			overall_activities_diversity <- total_activities>0?(-1*sum(class_counter collect((each/total_activities)*(each<=0?0:ln(each/total_activities))))):0;
		}
		result <- mean(base_grid where(each.day_diversity>0) collect(each.day_diversity)) ;
		write result;
		return result; 
	}
	
	float mean_diversity_day{
		float result;
		map<string,int> class_counter;
		loop i over:day_activities{
			add i::0 to:class_counter;
		}
		list<economic_unit> my_tmp_activities <- economic_unit where(each.sub_id in day_activities);
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			result <- 0.0;
		}
		else{
			result <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
		return result;
		
		/*ask base_grid{do compute_diversity_day;}
		result <- mean(base_grid where(each.day_diversity>0) collect(each.day_diversity)) ;
		write result;
		return result;*/
	}
	
	float mean_diversity_night{
		float result;
		map<string,int> class_counter;
		loop i over:night_activities{
			add i::0 to:class_counter;
		}
		list<economic_unit> my_tmp_activities <- economic_unit where(each.sub_id in night_activities);
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			result <- 0.0;
		}
		else{
			result <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
		/*ask base_grid{do compute_diversity_night;}
		result <- mean(base_grid where(each.night_diversity>0) collect(each.night_diversity)) ;
		write result;*/
		return result;
	}
	
	float mean_diversity_knowledge{
		float result;
		map<string,int> class_counter;
		loop i over:knowledge_activities{
			add i::0 to:class_counter;
		}
		list<economic_unit> my_tmp_activities <- economic_unit where(each.sub_id in knowledge_activities);
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			result <- 0.0;
		}
		else{
			result <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
		
		/*
		ask base_grid{do compute_diversity_knowledge;}
		result <- mean(base_grid where(each.knowledge_diversity>0) collect(each.knowledge_diversity)) ;
		write result;
		*/
		return result;
	}
	
	float mean_diversity_interaction{
		float result;
		map<string,int> class_counter;
		loop i over:interaction_places{
			add i::0 to:class_counter;
		}
		list<economic_unit> my_tmp_activities <- economic_unit where(each.sub_id in interaction_places);
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			result <- 0.0;
		}
		else{
			result <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
		
		/*
		ask base_grid{do compute_diversity_interaction;}
		result <- mean(base_grid where(each.interaction_diversity>0) collect(each.interaction_diversity)) ;
		write result;*/
		
		return result;
	}
	

	float mean_density_day{
		write "computing density day";
		float result;
		list<economic_unit> tmp_units <- economic_unit where(each.sub_id in day_activities);
		result <- length(economic_unit)>0?length(tmp_units)/length(economic_unit):0;
		/*result <- mean(base_grid where(each.day_density>0) collect(each.day_density)) ;
		write result;*/
		return result;
	}
	float mean_density_night{
		float result;
		list<economic_unit> tmp_units <- economic_unit where(each.sub_id in night_activities);
		result <- length(economic_unit)>0?length(tmp_units)/length(economic_unit):0;
		/*result <- mean(base_grid where(each.night_density>0) collect(each.night_density)) ;
		write result;*/
		return result;
	}
	float mean_density_knowledge{
		float result;
		list<economic_unit> tmp_units <- economic_unit where(each.sub_id in knowledge_activities);
		result <- length(economic_unit)>0?length(tmp_units)/length(economic_unit):0;
		/*result <- mean(base_grid where(each.knowledge_density>0) collect(each.knowledge_density)) ;
		write result;*/
		return result;
	}
	float mean_density_interactions{
		float result;
		list<economic_unit> tmp_units <- economic_unit where(each.sub_id in interaction_places);
		result <- length(economic_unit)>0?length(tmp_units)/length(economic_unit):0;
		/*result <- mean(base_grid where(each.interaction_density>0) collect(each.interaction_density)) ;
		write result;*/
		return result;
	}
	
	float hab_emp_ratio{
		float result;
		int nb_tertiary_activities <- length(economic_unit where(each.sub_id in tertiary_activities));
		int nb_households <- sum(current_active_blocks collect(each.nb_households)); 
		result <- nb_tertiary_activities / nb_households;
		return result;
	}
	
	//----------  USER INTERACTION  ------------------------------
	//Functions built to update heatmap values according to the input from the user
	//Currently it is under development. We are looking to use fields and mesh to show heatmaps (gama 1.8.2).
	//Currently we use "from_scenario" variable to distiguish the source of data


	/*
	 * EXAMPLE OF HOW WE MODEL HEALTH
	 * current_heatmap <- "health";
		//Radar values
		ask current_active_blocks{
			nb_different_health_equipment <- 0;
			loop class over:health_distances.keys{
				list<equipment> tmp_list <- health_facilities where(each.subtype = class) at_distance(health_distances[class]);
				nb_different_health_equipment <- empty(tmp_list)?nb_different_health_equipment:nb_different_health_equipment+1;
			}
			ind_proximity_2_health_equipment <- nb_different_health_equipment > min_health_equipment;
			list<people> my_people <- people where(each.home_block=self);
			ask my_people{
				ind_health_equipment_proximity <- myself.ind_proximity_2_health_equipment;
			}
			
			if length(my_people) = 0{
				health_proximity <- 0.0;
			}
			else{
				health_proximity <- length(my_people where(each.ind_health_equipment_proximity))/length(my_people);	
			}
			
		}
		ask ref_grid{
			list<blocks> my_blocks <- current_active_blocks at_distance(150);
			if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
			float value <- mean(my_blocks collect(each.health_proximity));
			ask heatmap inside(self){
				grid_value <- value;
			}
		}
		do spread_value(spread_value_factor);
	 */

	action heatmap2education{
		current_heatmap <- "education";
		ask ccu_heatmap{grid_value <- 0.0;}
		
		//Radar values
		ask current_active_blocks inside (first(ccu_limit+1000)){
			nb_different_education_equipment <- 0;
			loop class over:education_distances.keys{
				list<equipment> tmp_list <- education_facilities where(each.subtype = class) at_distance(education_distances[class]);
				nb_different_education_equipment <- empty(tmp_list)?nb_different_education_equipment:nb_different_education_equipment+1;
			}
			ind_proximity_2_education_equipment <- nb_different_education_equipment > min_education_equipment;
			list<people> my_people <- people where(each.home_block=self);
			ask my_people{
				ind_education_equipment_proximity <- myself.ind_proximity_2_education_equipment;
			}
			if length(my_people) = 0{
				education_proximity <- 0.0;
			}
			else{
				education_proximity <- length(my_people where(each.ind_education_equipment_proximity))/length(my_people);
			}
			ask ref_grid{
				list<blocks> my_blocks <- current_active_blocks at_distance(150);
				if my_blocks = nil or length(my_blocks) = 0 or my_blocks =[]{my_blocks <- [current_active_blocks closest_to(self)];}
				float value <- mean(my_blocks collect(each.education_proximity));
				ask heatmap inside(self){
					grid_value <- value;
				}
			}
			//int scenario_index <- scenario = 1?0:1;
			//dash_educational_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		//write length(people where(each.from_scenario=scenario and each.ind_education_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		/*ask current_active_blocks{
			if length(people where(each.home_block=self)) = 0{
				education_proximity <- 0.0;
			}
			else{
				list<people> my_people <- people where(each.home_block=self and each.ind_education_equipment_proximity);
				education_proximity <- length(my_people)/length(people where(each.home_block=self));	
			}
			
		}
		ask base_grid{
			list<heatmap> the_cells;
			list<blocks> my_blocks <- current_active_blocks overlapping self;
			ask my_blocks{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{grid_value <- mean(my_blocks collect(each.education_proximity));}
			}
		}*/
		/*ask education_facilities {
			//Here we obtain the shape of the block in order to update the grid values related to it
			blocks the_block <- current_active_blocks closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}
		}*/
		do spread_value(spread_value_factor);
	}
	action heatmap2culture{
		current_heatmap <- "culture";
		ask ccu_heatmap{grid_value <- 0.0;}
		
		//Radar values
		ask current_active_blocks{//} inside (first(ccu_limit)){
			nb_different_cultural_equipment <- 0;
			loop class over:culture_distances.keys{
				list<equipment> tmp_list <- culture_facilities where(each.subtype = class) at_distance(culture_distances[class]);
				nb_different_cultural_equipment <- empty(tmp_list)?nb_different_cultural_equipment:nb_different_cultural_equipment+1;
			}
			ind_proximity_2_cultural_equipment <- nb_different_cultural_equipment > min_culture_equipment;
			list<people> my_people <- people where(each.home_block=self);
			ask my_people{
				ind_cultural_equipment_proximity <- myself.ind_proximity_2_cultural_equipment;
			}
			if length(my_people) = 0{
				culture_proximity <- 0.0;
			}
			else{
				culture_proximity <- length(my_people where(each.ind_cultural_equipment_proximity))/length(my_people);	
			}
			ask ref_grid{
				list<blocks> my_blocks <- current_active_blocks at_distance(150);
				if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
				float value <- mean(my_blocks collect(each.culture_proximity));
				ask heatmap inside(self){
					grid_value <- value;
				}
			}
			//int scenario_index <- scenario = 1?0:1;
			//dash_cultural_equipment_proximity[scenario_index] <- length(people where(each.from_scenario=scenario and each.ind_cultural_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		}
		do spread_value(spread_value_factor);
		//write length(people where(each.from_scenario=scenario and each.ind_cultural_equipment_proximity=true))/length(people where(each.from_scenario=scenario));
		
		
		//Heatmap values
		/*ask ccu_heatmap{grid_value <- 0.0;}
		ask current_active_blocks{
			if length(people where(each.home_block=self)) = 0{
				culture_proximity <- 0.0;
			}
			else{
				list<people> my_people <- people where(each.home_block=self and each.ind_cultural_equipment_proximity);
				culture_proximity <- length(my_people)/length(people where(each.home_block=self));	
			}
			
		}
		ask base_grid{
			list<heatmap> the_cells;
			list<blocks> my_blocks <- current_active_blocks overlapping self;
			ask my_blocks{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{grid_value <- mean(my_blocks collect(each.culture_proximity));}
			}
		}*/
		/*ask culture_facilities{
			blocks the_block <- current_active_blocks closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}		
		}
		do spread_value(spread_value_factor);*/
	}
	
	action heatmap2health{
		current_heatmap <- "health";
		//Radar values
		ask current_active_blocks{
			nb_different_health_equipment <- 0;
			loop class over:health_distances.keys{
				list<equipment> tmp_list <- health_facilities where(each.subtype = class) at_distance(health_distances[class]);
				nb_different_health_equipment <- empty(tmp_list)?nb_different_health_equipment:nb_different_health_equipment+1;
			}
			ind_proximity_2_health_equipment <- nb_different_health_equipment > min_health_equipment;
			list<people> my_people <- people where(each.home_block=self);
			ask my_people{
				ind_health_equipment_proximity <- myself.ind_proximity_2_health_equipment;
			}
			
			if length(my_people) = 0{
				health_proximity <- 0.0;
			}
			else{
				health_proximity <- length(my_people where(each.ind_health_equipment_proximity))/length(my_people);	
			}
			
		}
		ask ref_grid{
			list<blocks> my_blocks <- current_active_blocks at_distance(150);
			if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
			float value <- mean(my_blocks collect(each.health_proximity));
			ask heatmap inside(self){
				grid_value <- value;
			}
		}
		do spread_value(spread_value_factor);
		
		
		//Heatmap values
		/*ask ccu_heatmap{grid_value <- 0.0;}
		ask current_active_blocks{
			if length(people where(each.home_block=self)) = 0{
				health_proximity <- 0.0;
			}
			else{
				list<people> my_people <- people where(each.home_block=self and each.ind_health_equipment_proximity);
				health_proximity <- length(my_people)/length(people where(each.home_block=self));	
			}
			
		}
		ask base_grid{
			list<heatmap> the_cells;
			list<blocks> my_blocks <- current_active_blocks overlapping self;
			ask my_blocks{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{grid_value <- mean(my_blocks collect(each.health_proximity));}
			}
		}
		*/
		/*ask health_facilities{
		 	blocks the_block <- current_active_blocks closest_to self;
			list<heatmap> the_cells;
			ask the_block{
				the_cells <- ccu_heatmap overlapping self;
				ask the_cells{
					grid_value <- 1.0;
				}
			}		
		}
		do spread_value(spread_value_factor);*/
	}
	
	action heatmap2sports{
	
		current_heatmap <- "sports";
		//Radar values
		ask current_active_blocks{
			nb_different_sports_equipment <- 0;
			loop class over:sports_distances.keys{
				list<equipment> tmp_list <- sports_facilities where(each.subtype = class) at_distance(sports_distances[class]);
				nb_different_sports_equipment <- empty(tmp_list)?nb_different_sports_equipment:nb_different_sports_equipment+1;
			}
			ind_proximity_2_sports_equipment <- nb_different_sports_equipment > min_sports_equipment;
			list<people> my_people <- people where(each.home_block=self);
			ask my_people{
				ind_sports_equipment_proximity <- myself.ind_proximity_2_sports_equipment;
			}
			
			if length(my_people) = 0{
				sports_proximity <- 0.0;
			}
			else{
				sports_proximity <- length(my_people where(each.ind_sports_equipment_proximity))/length(my_people);	
			}
			
		}
		ask ref_grid{
			list<blocks> my_blocks <- current_active_blocks at_distance(150);
			if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
			float value <- mean(my_blocks collect(each.sports_proximity));
			ask heatmap inside(self){
				grid_value <- value;
			}
		}
		do spread_value(spread_value_factor);
	  
		
		
		
		//Radar values
		/*
		current_heatmap <- "sports";
		ask current_active_blocks inside (first(ccu_limit)){
			nb_different_sports_equipment <- 0;
			loop class over:sports_distances.keys{
				list<equipment> tmp_list <- sports_facilities where(each.subtype = class) at_distance(sports_distances[class]);
				nb_different_sports_equipment <- empty(tmp_list)?nb_different_sports_equipment:nb_different_sports_equipment+1;
			}
			ind_proximity_2_sports_equipment <- nb_different_sports_equipment > min_sports_equipment;
			float value_sum <- 0.0;
			ask people where(each.home_block=self){
				ind_sports_equipment_proximity <- myself.ind_proximity_2_sports_equipment;
				value_sum <- value_sum + (ind_sports_equipment_proximity?1:0);
			}
		}
		*/
		//Heatmap values
		ask ccu_heatmap{grid_value <- 0.0;}
		 ask sports_facilities{
		 	blocks the_block <- current_active_blocks closest_to self;
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
		current_heatmap <- "mobility";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask current_active_blocks{
			list<people> my_people <- people where(each.home_block=self);
			mobility_access <- mean(my_people collect(each.mobility_accessibility));
		}
		ask ref_grid{
			list<blocks> my_blocks <- current_active_blocks at_distance(150);
			if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
			float value <- mean(my_blocks collect(each.mobility_access));
			ask heatmap inside(self){
				grid_value <- value;
			}
		}
		/*ask ref_grid{
			float value <- self.transportation_access;
			list<blocks> my_blocks <- current_active_blocks inside(100);
			//blocks my_blocks <- current_active_blocks closest_to self;
			if my_blocks = nil or length(my_blocks)=0 or my_blocks = []{my_blocks <- [current_active_blocks closest_to(self)];}
			list<heatmap> the_cells;
			ask my_blocks{
				using topology(world){
					the_cells <- ccu_heatmap inside(self);
						ask the_cells{grid_value <- my_blocks!=nil?mean(my_blocks collect(each.mobility_access)):0;//mean(my_blocks collect(each.mobility_access));}
					}
				}
				
			}
		}*/
		do spread_value(spread_value_factor);
	}
	
	//------------ HEATMAP SHOWS DIVERSITY
	action heatmap2daydiv{
		current_heatmap <- "day_diversity";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_diversity_day;
			ask heatmap inside(self){
				grid_value <- myself.day_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2nightdiv{
		current_heatmap <- "night_diversity";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_diversity_night;
			ask heatmap inside(self){
				grid_value <- myself.night_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	action heatmap2knowdiv{
		current_heatmap <- "knowledge_diversity";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_diversity_night;
			ask heatmap inside(self){
				grid_value <- myself.knowledge_diversity;
			}
		}
		do spread_value(spread_value_factor);
	}
	
	
	//------------ HEATMAP SHOWS DENSITY
	
	action heatmap2populationdensity{
		current_heatmap <- "population_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_population_living_inside;
		}
		int max_population_living_in_grid <- max(ref_grid collect(each.people_living_inside));
		ask ref_grid{
			ask heatmap inside(self){
				grid_value <- myself.people_living_inside/max_population_living_in_grid;
			}
		}
		do spread_value(spread_value_factor);
	}	
	action heatmap2householddensity{
		current_heatmap <- "household_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_household_inside;
		}
		int max_households_in_grid <- max(ref_grid collect(each.households_inside));
		ask ref_grid{
			ask heatmap inside(self){
				grid_value <- myself.households_inside/max_households_in_grid;
			}
		}
		do spread_value(spread_value_factor);
	}
	action heatmap2daydensity{
		current_heatmap <- "day_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_density_day;
			ask heatmap inside(self){
				grid_value <- myself.day_density;
			}
		}
		do spread_value(spread_value_factor);
	}
	action heatmap2nightdensity{
		current_heatmap <- "night_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_density_night;
			ask heatmap inside(self){
				grid_value <- myself.night_density;
			}
		}
		do spread_value(spread_value_factor);
	}
	action heatmap2knowledgedensity{
		current_heatmap <- "knowledge_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_density_knowledge;
			ask heatmap inside(self){
				grid_value <- myself.knowledge_density;
			}
		}
		do spread_value(spread_value_factor);
	}
	action heatmap2interactiondensity{
		current_heatmap <- "interaction_density";
		ask ccu_heatmap{grid_value <- 0.0;}
		ask ref_grid{
			do compute_density_interaction;
			ask heatmap inside(self){
				grid_value <- myself.interaction_density;
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
				grid_value <- grid_value*spread_factor + mean(my_nb where(not dead(each))  collect(each.grid_value))*(1-spread_factor);
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
	bool valid <- true;
	aspect default{
		draw shape wireframe:true border:#red;
	}
	aspect heat{
		//draw shape color:rgb((1-grid_value)*255,grid_value*255,100,0.7);
		if show_heatmap{
			my_color <- update_color_new(current_heatmap);
			float intensity <- grid_value=0?0.1:grid_value;
			intensity <- grid_value>0.65?0.65:grid_value;
			draw shape color:rgb(my_color,grid_value=1?1.2:intensity);// border:rgb(my_color,grid_value=0?0.1:intensity);
		}	
	}
	
	rgb update_color_new(string current_hm){
		rgb result;
		string my_class <- "default";
		loop i over:heatmap_names.keys{
			if current_hm in heatmap_names[i]{my_class <- i;}
		}
		switch(my_class){
			match "population/housing"{result <- rgb(242-int(grid_value*127), 226-int(grid_value*224),5-int(grid_value*3));}
			match "facilities"{result <- rgb(234-int(grid_value*229), 236-int(grid_value*229), 255-int(grid_value*100));}
			match "activities_density"{result <- rgb(255-int(grid_value*23), 232-int(grid_value*151), 249-int(grid_value*140));}
			match "activities_diversity"{result <- rgb(255-(255*grid_value), 40+(190*grid_value),0);}
			match "default"{result <- rgb(214-int(grid_value*160), 217-int(grid_value*160), 193-int(grid_value*168));}
		}
		return result;
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

species green_area{
	float surface_area;
}

species project{
	
	string id;
	int from_scenario;
	string block_id;
	string project_name;
	string letter;
	int population;
	string use_type;
	int nb_ec_units; //Nb of economic units
	int UBS;
	float green_areas_m2;
	float building_m2;
	int viv_eco;
	int viv_med;
	int viv_res;
	int green_area;
	list<economic_unit> my_new_activities;
	list<people> new_people;
	//Function to be eliminated
	/*action create_new_population{
		blocks my_block <- first(blocks where(each.from_scenario=from_scenario and each.id=block_id));
		create people number:my_block.nb_people/5 returns:new_people;
		ask new_people{
			from_scenario <- myself.from_scenario;
			home_point <- any_location_in(my_block);
			location <- home_point;
			home_block <- my_block;
		}
		add my_block to:current_active_blocks;
	}*/
	
	//Function that computes the random activites that are coming with the project, using the data about the allowed activities for this project.
	action create_new_activities{
		my_new_activities <- [];
		//Check the permited land uses for the project. 
		list<string> allowed_activities_for_me <- allowed_activities[use_type];
		loop i over: sample(allowed_activities_for_me,nb_ec_units,true){
			create economic_unit with:[from_scenario::from_scenario,sub_id::i] returns:new_unit;
			economic_unit new_unit_ <- first(new_unit);
			blocks my_block <-first( blocks where(each.id=block_id));
			ask new_unit_{
				location <- any_location_in (my_block);
			}
			add first(new_unit) to:my_new_activities;
		}
	}
	
	action activate{
		do create_new_activities;
		blocks my_block <- first( blocks where(each.id=block_id and from_scenario=self.from_scenario));
		add my_block to:current_active_blocks;
		ask my_block{
			write "adding "+length(my_households)+" new households";
			ask my_households{
				write "before: "+length(current_active_households);
				current_active_households <- current_active_households + [self];
				//add self to:current_active_households;
				write "after: "+length(current_active_households);
			}
		}
		ask my_block{
			nb_people <- myself.population;
			nb_households <- nb_households + viv_eco + viv_med + viv_res;
			write "project "+myself.letter+ " adding "+nb_people+" people";
			create people number:self.nb_people/nb_people_prop returns:arriving_people with:[
				target_block::one_of(current_active_blocks-self),
				from_scenario::myself.from_scenario
			]{
				home_block <- myself;
				home_point <- any_location_in(home_block);
				location <- home_point;
				mobility_type <- select_mobility_mode();
				do compute_mobility_accessibility();																															//<-gama-issue14-may05
				
			}
			myself.new_people <- arriving_people;
		}
		//Activar aquí áreas verdes
	}
	action deactivate{
		ask my_new_activities{do die;}
		ask new_people {to_be_killed <- true;}
		list<blocks> blocks_tbr <- current_active_blocks where(each.id=block_id);
		ask blocks_tbr{
			remove self from:current_active_blocks;
			
			ask my_households{
				//remove self from:current_active_households;
				write "before: "+length(current_active_households);
				current_active_households <- current_active_households - [self];
				//add self to:current_active_households;
				write "after: "+length(current_active_households);
			}
		}
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
		draw square(1) color:rgb (186, 58, 197, 255) border:rgb (186, 58, 197, 255);
	}
}

species intervention_area{
	int active_scenario;
	string blocksS1_str;
	string blocksS2_str;
	string blocksS3_str;
	list<list<blocks>> blocks_by_scenario <- [[],[],[]];
	string area_name;
	string id;
	string associated_projects_str;
	list<project> associated_projects;
	action activate_scenario(int new_scenario){
		if active_scenario != new_scenario{
			//int aux_people_tbk <- 0;
			write "-----------";
			write area_name+": changing scenario "+active_scenario+" to "+new_scenario;
			try{
				ask associated_projects where(each.from_scenario=active_scenario){
					do deactivate;
				}
				/*ask blocks_by_scenario[active_scenario-1]{
					ask people where(each.from_scenario=myself.active_scenario and each.home_block=self){
						write "im gonna die";
						do die;
						//to_be_killed <- true;
					}
					remove self from:current_active_blocks;
				}*/
				ask associated_projects where(each.from_scenario=new_scenario){
					do activate;
				}

				
				/*write "Area :"+area_name;
				write "Current people: "+length(people);
				write "people to be killed: "+aux_people_tbk;
				int aux_people_tba <- 0;*/
				
				/*ask blocks_by_scenario[new_scenario-1]{
					write "new block id: "+id;
					add self to:current_active_blocks;
					create people number:self.nb_people/7 with:[
						target_block::one_of(blocks-self),
						from_scenario::new_scenario
					]{
						home_block <- myself;
						home_point <- any_location_in(home_block);
						location <- home_point;
						mobility_type <- select_mobility_mode();
						do compute_mobility_accessibility();
						//aux_people_tba <- aux_people_tba + 1;
					}
				}*/
				
				//write "people added: "+aux_people_tba;
			}
			scenario_changed <- true;
			time_2_save_data <- delay_before_export_data;
			time_2_update_heatmap <- delay_before_update_heatmap;
			allow_export_current_data <- true;
			active_scenario <- new_scenario;
		}
		
	}
	aspect default{
		if(show_information){
			draw shape wireframe:true border:#yellow;
			draw area_name+string(active_scenario) color:#white font:font("Helvetica", 30 , #bold)at:{location.x,location.y,20};	
		}
	}
}
//***********************************************************

//Entry points
species entry_point{
	float rate <- 0.0;
}
species cultural_event{
	string event_name;
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
species base_grid{
	int from_scenario;
	
	//Indicators
	float mobility_access;
	float night_diversity;
	float day_diversity;
	float knowledge_diversity;
	float interaction_diversity;
	float overall_activities_diversity;
	float day_density;
	float night_density;
	float knowledge_density;
	float interaction_density;
	float social_interactions;
	
	//Auxiliar variables
	int people_living_inside;
	int households_inside;
	list<economic_unit> activities_inside;
	list<economic_unit> my_tmp_activities;
	
	action compute_mobility_access{
		
	}
	
	action compute_diversity_day{
		activities_inside <- economic_unit inside self;
		map<string,int> class_counter;
		loop i over:day_activities{
			add i::0 to:class_counter;
		}
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in day_activities);
		//day_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;

			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			day_diversity <- 0.0;
		}
		else{
			day_diversity <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
		
	}
	
	action compute_diversity_night{
		activities_inside <- economic_unit inside self;
		map<string,int> class_counter;
		loop i over:night_activities{
			add i::0 to:class_counter;
		}
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in night_activities);
		//night_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			night_diversity <- 0.0;
		}
		else{
			night_diversity <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
	}
	action compute_diversity_knowledge{
		activities_inside <- economic_unit inside self;
		map<string,int> class_counter;
		loop i over:knowledge_activities{
			add i::0 to:class_counter;
		}
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in knowledge_activities);
		//knowledge_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			knowledge_diversity <- 0.0;
		}
		else{
			knowledge_diversity <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
	}
	action compute_diversity_interaction{
		activities_inside <- economic_unit inside self;
		map<string,int> class_counter;
		loop i over:interaction_places{
			add i::0 to:class_counter;
		}
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in interaction_places);
		//interaction_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
		if not empty(my_tmp_activities){
			loop act over:my_tmp_activities{
				class_counter[act.sub_id] <- class_counter[act.sub_id] + 1;
			}
		}
		int total_activities <- sum(class_counter.values);
		if total_activities=0{
			interaction_diversity <- 0.0;
		}
		else{
			interaction_diversity <- -1*sum(class_counter.values collect((each/total_activities)*(each<=0?0:ln(each/total_activities))));	
		}
	}
	action compute_density_day{
		activities_inside <- economic_unit inside self;
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in day_activities);
		day_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
	}
	action compute_density_night{
		activities_inside <- economic_unit inside self;
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in night_activities);
		night_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
	}
	action compute_density_knowledge{
		activities_inside <- economic_unit inside self;
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in knowledge_activities);
		knowledge_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
	}
	action compute_density_interaction{
		activities_inside <- economic_unit inside self;
		my_tmp_activities <- economic_unit inside(self) where(each.sub_id in interaction_places);
		interaction_density <- length(economic_unit inside (self))>0?length(my_tmp_activities)/length(economic_unit inside (self)):0;
	}
	action compute_population_living_inside{
		people_living_inside <- length(people where(self covers each.home_point));
	}
	action compute_household_inside{
		households_inside <- length(current_active_households where(self covers each));
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
	int nb_households;
	list<household> my_households;
	float block_area;
	bool valid <- false;
	string viv_type;
	int viv_eco;
	int viv_med;
	int viv_res;
	
	//Indicators that are computed at block level
	float mobility_access;
	float education_proximity;
	float culture_proximity;
	float health_proximity;
	float sports_proximity;
	float energy_requirement;
	float waste_generation;
	float population_density;
	float water_requirement;
	
	
	//Cultural equipment
	int nb_different_cultural_equipment <- 0;
	bool ind_proximity_2_cultural_equipment <- false;
	int nb_different_education_equipment <- 0;
	bool ind_proximity_2_education_equipment <- false;
	int nb_different_health_equipment <- 0;
	bool ind_proximity_2_health_equipment <- false;
	int nb_different_sports_equipment <- 0;
	bool ind_proximity_2_sports_equipment <- false;
	
	action compute_energy_requirement{
		if from_scenario = 1{
			//We separate scenario 1 from the others in this indicator because there is no information about the current classification of living spaces. So we approximate this value.
			
			float req_by_block <- nb_people*energy_requirement_map[viv_type];		
			energy_requirement <- nb_people>0?req_by_block/nb_people:0;	
		}
		else{
			float req_by_block <- (viv_eco*energy_requirement_map["Económica"])+(viv_med*energy_requirement_map["Media"]+(viv_res*energy_requirement_map["Residencial"]));
			energy_requirement <- nb_people>0?req_by_block/nb_people:0;
		}
	}
	action compute_waste_generation{
		if from_scenario = 1{
			//We separate scenario 1 from the others in this indicator because there is no information about the current classification of living spaces. So we approximate this value.
			float waste_by_block <- nb_people*waste_generation_map[viv_type];		
			waste_generation <- nb_people>0?waste_by_block/nb_people:0;	
		}
		else{
			float waste_by_block <- (viv_eco*waste_generation_map["Económica"])+(viv_med*waste_generation_map["Media"]+(viv_res*waste_generation_map["Residencial"]));
			waste_generation <- nb_people>0?waste_by_block/nb_people:0;
		}
	}
	action compute_water_requirement{
		if from_scenario = 1{
			//We separate scenario 1 from the others in this indicator because there is no information about the current classification of living spaces. So we approximate this value.
			float aprox_viv <- nb_people/3.6;
			float req_by_block <- aprox_viv*water_requirement_map[viv_type];		
			water_requirement <- nb_people>0?req_by_block/nb_people:0;	
		}
		else{
			float req_by_block <- (viv_eco*water_requirement_map["Económica"])+(viv_med*water_requirement_map["Media"]+(viv_res*water_requirement_map["Residencial"]));
			water_requirement <- nb_people>0?req_by_block/nb_people:0;
		}
	}
	action compute_population_density{
		float ha <- block_area * 0.0001;
		population_density <- ha>0?nb_people / ha:0;
	}
	
	aspect default{
		if self in current_active_blocks and not show_satellite{
			draw shape color:rgb(100,100,100,0.2);// border:#gray width:5.0;
		}
		//draw shape wireframe:false color:valid?#green:#red;// border:#blue;
	}
}

species household{
	int from_scenario;
	aspect default{
		if self in current_active_households{
			draw triangle(5) color:from_scenario=1?#green:rgb (185, 19, 172, 255) wireframe:true;
		}
		
	}
}
species roads{
	int from_scenario;
	aspect default{
		draw shape color:#gray;
	}
}

species aux_roads{
	int from_scenario;
	float length;
}

//This species is created to draw a background with the satellite image
species satellite_background{
	image_file satellite;
	init{
		satellite <- image_file("../includes/img/satellite.png");
	}
	aspect default{
		if show_satellite{
			draw shape border:#red texture:satellite;
		}
		
	}
}

species people{// skills:[moving]{
	
	//Related to individual indicators
	float mobility_accessibility <- 0.0;
	bool ind_public_transport_coverage			<- false;
	bool ind_cultural_equipment_proximity 		<- false;
	bool ind_education_equipment_proximity 	<- false;
	bool ind_health_equipment_proximity			<- false;
	bool ind_sports_equipment_proximity 		<- false;
	
	//Variables related to scenarios
	int from_scenario;
	bool to_be_killed <- false;
	
	//Related to mobility
	blocks home_block;
	point home_point;
	blocks target_block;
	point target_point;
	int point_counter <- 0;
	string current_destinity <- "work" among:["home","work"];
	map<date,string> agenda_day;
	string mobility_type;
	bool currently_moving <- false;

	//This action is to compute mobility_accessibility
	action compute_mobility_accessibility{
		int transport_accessibilty_count <- 0;
		list<float> distances <- [];

		try{
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

	//gama-issue14-may05 Removed all functions that compute paths, or edit them, etc. We do not use road networks in this model anymore.
	//gama-issue14-may05 Also removed functions related to agenda as people will not move.
	reflex kill_agent when: to_be_killed{
		do die;
	}
	
	//This reflex controls the agent's activities to do during the day
	reflex update_agenda when: (every(#day)) or empty(agenda_day){
		agenda_day <- [];
		int hours_for_activities <- rnd(6,10);
		int sum <- 0;
		int nb_activities <- rnd(6,10);
		int hour_for_go_out <- rnd(7,22-hours_for_activities);
		int hours_per_activity <- int(hours_for_activities/nb_activities);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,hour_for_go_out,rnd(0,59),rnd(0,59));
		
		loop i from:0 to: nb_activities{ //Number of activities
			activity_date <- activity_date + sum#hours;
			agenda_day <+ (activity_date::"activity");
			sum <- sum + hours_per_activity;
		}
		
		activity_date <- activity_date + sum#hours;
		agenda_day <+ (activity_date::"home");
	}
	
	reflex update_activity when:not dead(self) and not empty(agenda_day){
		try{
			if after(agenda_day.keys[0]) {
			  	string current_activity <-agenda_day.values[0];
				target_block <- current_activity = "activity"?one_of(blocks):home_block;
				agenda_day>>first(agenda_day);
				//write ""+name+":"+"creating a car";
				create car{																												//gama-issue14-may08->
					source_sc <- "activities";
					target_block <- myself.target_block;
					max_speed <- 40 #km / #h;
					vehicle_length <- 4.0 #m;
					right_side_driving <- true;
					proba_lane_change_up <- 0.1 + (rnd(500) / 500);
					proba_lane_change_down <- 0.5 + (rnd(500) / 500);
					location <- (intersection where empty(each.stop) closest_to myself.home_point).location;
					security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
					proba_respect_priorities <- 1.0 - rnd(200 / 1000);
					proba_respect_stops <- [1.0];
					proba_block_node <- 0.0;
					proba_use_linked_road <- 0.0;
					max_acceleration <- 5 / 3.6;
					speed_coeff <- 1.2 - (rnd(400) / 1000);
					threshold_stucked <- int((1 + rnd(5)) #mn);
					proba_breakdown <- 0.00001;
				}																															//<-gama-issue14-may08
		 	 }
		}
	 }	

	aspect default{
		if(show_people){
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
experiment "Run CityScope" type:gui autorun:false{       //Experiment at scale 1:1000 of the University Cultural District
	output{
		display my_display type:java2D {
	        chart "my_chart" type: series {
		        data "numberA" value: length(car) color: #red;
	        }
   		 }
		display gui type:opengl background:#black axes:false  fullscreen:0{
			camera 'default' location: {1007.3931,681.2155,1270.1296} target: {1009.0202,671.3018,0.0};
	
			overlay size:{0,0} position:{0.1,0.1} transparency:0.5{
				draw "abcdefghiíjklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 55, #bold);
				int the_day <- current_date.day-starting_date.day +1;
				string str_day <- int_to_day[the_day];
				string minute <- current_date.minute<10?(string(0)+current_date.minute):current_date.minute;
				draw " "+current_date.hour+":"+ minute at:{30#px,30#px} color:#white font: font("Arial", 55,#bold);
			}
			species satellite_background aspect:default refresh:true;
			species ccu_limit aspect:default refresh:true;
			species blocks aspect:default;
			species people aspect:default;
			species car aspect:default; //gama-issue14-may05
			species heatmap aspect:heat;
			species intervention_area aspect:default;
			
			//Keyboard events
			event "h" {show_heatmap <- !show_heatmap;} //Heatmap display
			event "s" action:heatmap2health;
			event "e" action:heatmap2education;
			event "c" action:heatmap2culture;
			event "x" action:heatmap2sports;
			event "d" action:heatmap2daydiv;
			event "n" action:heatmap2nightdiv;
			event "w" action:heatmap2knowdiv;
			
			event "u" action:heatmap2daydensity;
			event "i" action:heatmap2nightdensity;
			event "o" action:heatmap2knowledgedensity;
			event "p" action:heatmap2interactiondensity;
			event "l" action:heatmap2populationdensity;
			event "L" action:heatmap2householddensity;
			
			event "m" action:heatmap2mobility;
			event "q" action:show_satellite_action;
			event "t" action:activate_scenario1;
			event "y" action:activate_scenario2;
			
			//Events to change scenario
			event "A" action:change_scenario_A;
			event "B" action:change_scenario_B;
			event "F" action:change_scenario_K;
			event "I" action:change_scenario_I;
			event "L" action:change_scenario_L;
		}
	}
}
