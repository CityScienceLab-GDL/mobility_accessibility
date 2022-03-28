/**
* Name: filesvalidator
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model CityScope
import "constants.gaml"


global{
	
	//Shape files
	
	//Environmental shapes
	file dcu_limit_shp <- file(dcu_limits_filename);
	file ccu_limit_shp <- file(main_shp_path+"poligono_1_1000/poligono_mesa_dcu.shp");
	
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
	geometry shape <- envelope(dcu_limit_shp);
	string scenario <- "A";
	
	
	//Path  variables
	graph roads_network;
	map<string,path> paths;
	map roads_weight;
	
	//Heatmap  variables
	list<heatmap> ccu_heatmap;
	
	//Indicators  variables
	list<equipment> education_facilities;
	list<equipment> culture_facilities;
	list<equipment> health_facilities;
	list<diversity_grid> div_grid;
	
	//Visualization variables
	map<int,string> int_to_day <- [1::"Jueves",2::"Viernes",3::"Sábado",4::"Domingo",5::"Lunes",6::"Martes",7::"Miércoles"];

	
	init{
		
		
		//Simulation specific variables
		step 					<- 10#seconds;
		starting_date 	<- date("2022-3-23 06:00:00");
		
		
		//Create environment agents
		create ccu_limit from:ccu_limit_shp;
		
		//Create environment agents from scenario A
		create roads from:s1_roads_shp with:[from_scenario::"A"];
		create blocks from:s1_blocks_shp with:[from_scenario::"A",nb_people::int(read("POB1"))]{
			create people number:int(nb_people/15) with:[home_block::self,target_block::one_of(blocks-self)]{
				from_scenario <- "A";
				location <- any_location_in(home_block);
			}
		}
		create equipment from:s1_equipment_shp with:[type::string(read("tipo_equip"))];
		create diversity_grid from:s1_grid_shp with:[night_diversity::float(read("ID_NOCHE")),day_diversity::float(read("ID_DIA")),knowledge_diversity::float(read("ID_CONOCIM"))];
		
		//Create environment agents from scenario B
		create roads from:s2_roads_shp with:[from_scenario::"B"];
		create blocks from:s2_blocks_shp with:[from_scenario::"B",nb_people::int(read("POB1"))]{
			create people number:int(nb_people/15) with:[home_block::self,target_block::one_of(blocks-self)]{
				from_scenario <- "B";
				location <- any_location_in(home_block);
			}
		}
		
		//Create road network
		roads_weight <- roads as_map (each:: each.shape.perimeter);
		roads_network <- roads as_intersection_graph 1.0 with_weights roads_weight;
		
		//Clean memory
		ccu_limit_shp 				<- [];
		s1_roads_shp 				<- [];
		s1_blocks_shp 				<- [];
		s1_equipment_shp 		<-[];
		s1_grid_shp 					<- [];
		
		ask ccu_limit{
			ccu_heatmap 				<- heatmap inside(self);
			education_facilities 	<- equipment inside(self) where(each.type="Educación");
			culture_facilities 		<- equipment inside(self) where(each.type="Cultura");
			health_facilities 			<- equipment inside(self) where(each.type="Salud");
			div_grid							<- diversity_grid inside(self);
		}
		
		write "education:"+ length(education_facilities);
		write "culture:"+ length(culture_facilities);
		write "health:"+ length(health_facilities);
		//Ask people to initialize paths
		//ask people{do init_path;}
		
		
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
	
	action select_scenario_a{scenario <- "A";}
	action select_scenario_b{scenario <- "B";}
	action heatmap2education{
		ask ccu_heatmap{
			grid_value <- 0.0;
		}
		ask education_facilities{
			
			ask ccu_heatmap at_distance(1000){
				grid_value <- grid_value+(1-(2000-(self distance_to myself))/2000);
				grid_value <- grid_value * 1.1; //THIS IS TEMPORAL, JUST TO INCREASE THE VISUALIZATION
			}
		}
		do spread_value(2);
		/*--- TEST
		 * ask ccu_heatmap{
			equipment closest_facility <- education_facilities at_distance distance2education closest_to self;
			grid_value <- closest_facility=nil?0:max(1-(closest_facility distance_to self)/distance2education,0);
		}*/
	}
	action heatmap2culture{
		ask ccu_heatmap{
			grid_value <- 0.0;
		}
		ask culture_facilities{
			ask ccu_heatmap at_distance(1000){
				grid_value <- grid_value+(1-(2000-(self distance_to myself))/2000);
				grid_value <- grid_value * 1.3; //THIS IS TEMPORAL, JUST TO INCREASE THE VISUALIZATION
			}
		}
		do spread_value(2);
	}
	action heatmap2health{
		ask ccu_heatmap{
			grid_value <- 0.0;
		}
		ask health_facilities{
			ask ccu_heatmap at_distance(1000){
				grid_value <- grid_value+(1-(2000-(self distance_to myself))/2000);
				grid_value <- grid_value * 1.3; //THIS IS TEMPORAL, JUST TO INCREASE THE VISUALIZATION
			}
		}
		do spread_value(2);
	}
	action heatmap2daydiv{
		ask ccu_heatmap{
			grid_value <- 0.0;
		}
		ask div_grid{
			ask heatmap inside(self){
				grid_value <- myself.day_diversity;
			}
		}
		do spread_value(5);
	}
	//-------------------------------------------
	
	
	
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
				grid_value <- grid_value*0.6 + mean(my_nb  collect(each.grid_value))*0.4;
			}
		}
		
	}
	//-----------------------------------------------------------------
	
	
}

//------------------ HEATMAP CELLS ------------------------------------------
grid heatmap width:world.shape.width/25 height:world.shape.height/25{
	bool valid <- true;
	aspect default{
		draw shape wireframe:true border:#red;
	}
	aspect heat{
		//draw shape color:rgb((1-grid_value)*255,grid_value*255,100,0.7);
		draw shape color:rgb(200,100,100,grid_value);
	}
}

//------------------ SPECIES -----------------------------------------------------

//This diversity grid is used to initialize the diversity value. Once the simulation starts, the idea is to update such value from the scenario configuration.
species diversity_grid{
	float night_diversity;
	float day_diversity;
	float knowledge_diversity;
	aspect default{
		draw shape border:#red color:rgb(200,20,20,day_diversity/max_diversity);
	}
}
species equipment{
	bool valid <- false;
	string type;
	aspect by_type{
		if type="Cultura"{color <- #green;}
		else if type="Salud"{color<- #blue;}
		else if type = "Educación"{color<-#cyan;}
		draw square(20) color: color;
	}
}
species ccu_limit{
	aspect default{
		draw shape wireframe:true border:#white;
	}
}
species blocks{
	string from_scenario;
	int nb_people;
	bool valid <- false;
	aspect default{
		if scenario="B" and from_scenario="B"{
			draw shape color:rgb(100,100,100,0.2);
		}
		else if scenario = "A" and from_scenario ="A"{
			draw shape color:rgb(100,100,100,0.2);
		}
		//draw shape wireframe:false color:valid?#green:#red;// border:#blue;
	}
}
species roads{
	string from_scenario;
	aspect default{
		draw shape color:#gray;
	}
}
species people skills:[moving]{
	
	//Variables related to scenarios
	string from_scenario;
	
	//Related to mobility
	blocks home_block;
	blocks target_block;
	point target_point;
	path roads_path;
	list<point> my_path;
	int point_counter <- 0;
	string current_destinity <- "work" among:["home","work"];
	map<date,string> agenda_day;


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
	reflex moving{
		do goto target:target_point on:roads_network speed:0.1;
		//do follow path:roads_path;
	}
	
	
	aspect default{
		if scenario="A" and from_scenario="A"{
			draw circle(5) color:#yellow;
		}
		if scenario="B" and from_scenario="B"{
			draw circle(5) color:#green;
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
experiment mesa_1a1000 type:gui{
	output{
		display gui type:opengl fullscreen:0 background:#black axes:false{
			//camera 'default' location: {1480.2725,1623.8021,1876.6855} target: {1481.4065,1611.7894,0.0};
			camera 'default' location: {1480.2725,1623.7021,1876.6855} target: {1481.4065,1611.7894,0.0};
			overlay size:{0.7,0.1} position:{0.1,0.1} transparency:1.0{
				draw "abcdefghiíjklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 55, #bold);
				int the_day <- current_date.day-starting_date.day +1;
				string str_day <- int_to_day[the_day];
				string minute <- current_date.minute<10?(string(0)+current_date.minute):current_date.minute;
				draw str_day+" "+current_date.hour+":"+ minute at:{30#px,30#px} color:#white font: font("Arial", 55,#bold);
				//draw "Días: "+int(timeElapsed/86400) at:{30#px,60#px} color:#white font: font("Arial", 25,#bold);
				//draw "Horas: "+mod(int(timeElapsed/3600),24) at:{30#px,100#px} color:#white font: font("Arial", 25,#bold);
			}
			species blocks aspect:default;
			species heatmap aspect:heat;
			species people aspect:default;
			species ccu_limit aspect:default refresh:false;
			
			//Keyboard events
			event a action:select_scenario_a;
			event b action:select_scenario_b;
			event h action:heatmap2health;
			event e action:heatmap2education;
			event c action:heatmap2culture;
			event d action:heatmap2daydiv;
		}
	}
}