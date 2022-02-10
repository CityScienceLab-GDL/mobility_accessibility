/**
* Name: inegi2shp
* This model extracts relevant data from the shape files from INEGI (Mexico). Then, it creates a shape file for people. 
* Author: Gamaliel Palomo, Mario Siller
* Tags: 
*/


model inegi2shp
import "../constants.gaml"
global{
	file inegi_shp <- file("../../includes/shp/dcu_manzanas_inegi_2020.shp");
	file denue_shp <- file("../../includes/shp/denue_2021a.shp");
	
	geometry shape <- envelope(inegi_shp);
	int tot_0to2 					<-0;
	int tot_3to5 					<-0;
	int tot_6to11 					<-0;
	int tot_12to14 				<-0;
	int tot_15to17 				<-0;
	int tot_18to24 				<-0;
	int tot_25to64 				<-0;
	int tot_65_and_more 		<-0;
	int tot_people 				<-0;
	
	int range 	parameter:"range" category:"Model parameters" 	<- 10 min:0 max:100;
	int family_counter <- 0;
	
	init{
		create block from:inegi_shp with:[
			id::string(read("CVEGEO")),
			nb_people::int(read("POBTOT")),
			nb_0to2::int(read("P_0A2")),
			nb_3to5::int(read("P_3A5")),
			nb_6to11::int(read("P_6A11")),
			nb_12to14::int(read("P_12A14")),
			nb_15to17::int(read("P_15A17")),
			nb_18to24::int(read("P_18A24")),
			nb_65_and_more::int(read("POB65_MAS"))
			
		]{
			nb_25to64				<- nb_people-nb_0to2-nb_3to5-nb_6to11-nb_12to14-nb_15to17-nb_18to24-nb_65_and_more;
			tot_0to2					<- tot_0to2 + nb_0to2;
			tot_3to5					<- tot_3to5 + nb_3to5;
			tot_6to11				<- tot_6to11 + nb_6to11;
			tot_12to14			<- tot_12to14 + nb_12to14;
			tot_15to17			<- tot_15to17 + nb_15to17;
			tot_18to24			<- tot_18to24 + nb_18to24;
			tot_65_and_more			<- tot_65_and_more + nb_65_and_more;
			tot_25to64 				<- tot_25to64 + nb_25to64;//- tot_65_and_more - tot_0to2 -tot_3to5 - tot_6to11 - tot_12to14 - tot_15to17 - tot_18to24;
		}
		inegi_shp <- [];
		create workplace from:denue_shp with:[place_name::string(read("nom_estab")),str_nb_employees::string(read("per_ocu")),id::string(read("id")),activity_code::string(read("codigo_act"))];
		denue_shp <- [];
		int available_jobs <- 0;
		ask workplace{
			list words <- str_nb_employees split_with(" ");
			if words[1] = "a"{
				nb_employees <- int(words[2]);
			}
			else if words[1] = "y"{
				nb_employees <- int(words[0]);
			}
			available_jobs <- available_jobs + nb_employees;
		}
		write "available jobs: "+available_jobs;
		write "available work places: "+length(workplace);
		
		ask block{
			create people number:nb_0to2 {
				activity_type <- "idle";
				age <- rnd(0,2);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_3to5 {
				activity_type <- "idle";
				age <- rnd(3,5);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_6to11 {
				activity_type <- "student";
				age <- rnd(6,11);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_12to14 {
				activity_type <- "student";
				age <- rnd(12,14);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_15to17 {
				activity_type <- "student";
				age <- rnd(15,17);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_18to24 {
				activity_type <- "student";
				age <- rnd(18,24);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
			create people number:nb_25to64 {
				activity_type <- "worker";
				age <- rnd(25,64);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
				
			}
			create people number:nb_65_and_more {
				activity_type <- "idle";
				age <- rnd(65,100);
				location <- any_location_in(myself);
				homeblock_id <- myself.id;
			}
		}
		ask people{
			mobility_mode <- select_mobility_mode();
		}
		write "Total people: "+sum(block collect(each.nb_25to64));
		write "Agents people: "length(people);
		ask workplace{
			loop i from:1 to:nb_employees{
				//People who work inside the polygon
				ask one_of(people where(each.activity_type="worker" and each.activity_id = nil)){
					activity_id <- myself.id;
				}
			}
		}
		//People who work out of the polygon
		ask people where(each.activity_type = "worker" and each.activity_id = nil){
			activity_id <- "out";
		}
		list<workplace> schools <- workplace where(each.activity_code in universities);
		ask people where(each.activity_type = "student" and each.activity_id = nil){
			activity_id <- one_of(schools).id;
		}
		/* 
		 * This part of the code is to build families
		ask block{
			int nb_families <- int(nb_people/family_size);
			list<people> people_living_here <- create_people();
			write self.name + " ---------------------------";
			loop i from:1 to: nb_families{
				point family_location <- any_location_in(self);
				write "Family "+i+":";
				list<people> current_family;
				loop j from:1 to:family_size{
					people choosen_one <- one_of(people_living_here);
					add choosen_one to:current_family;
					remove choosen_one from:people_living_here;
				}
				ask current_family{
					family_id <- family_counter;
					location <- {family_location.x+rnd(-5,5),family_location.y+rnd(-5,5)};
					my_family <- current_family;
					write my_family;
				}
				family_counter <- family_counter + 1;
			}
		}*/
		/*create road from:roads_shp;
		weight_map 			<- road as_map(each::each.shape.perimeter);
		road_network 		<- as_edge_graph(road) with_weights weight_map;
		roads_shp <- [];
		int components <- length(connected_components_of(road_network));
		write "Graph components: "+ components;		
		save road_network to:"road_network.txt" type:"text" rewrite:true;
		create test_point number:1000;
		
		ask people where(each.age>=25 and each.age<65 and each.my_workplace != nil){
			path the_path <- path_between(road_network,self.location,self.my_workplace.location);
			add "home-work"::the_path to: my_paths;
			write the_path;
		}*/
		save people to:"../../includes/shp/people.shp" type:"shp" attributes:["age"::age,mobility_mode::"mobility_mode","activity_type"::activity_type,"activity_id"::my_workplace.id] crs:"EPSG:4326";
	}
	
}

species people {
	
	string homeblock_id;
	string mobility_mode;
	string activity_type;
	string activity_id <- nil;
	
	int age;
	string my_workplace_str;
	workplace my_workplace <- nil;
	map<string,path> my_paths;
	
	//Mobility
	point target;
	float speed 					<- 1.4;
	string mobility_profile 	<- one_of(["bus","car","walk","bicycle"]);
	
	//Social-economical variables
	bool essential_worker;
	
	//Family
	//int family_id;
	//list<people> my_family;
	
	string select_mobility_mode{
		float sum <- 0.0;
		float selection <- rnd(100)/100;
		loop mode over:activity_type="student"?student_mobility_percentages.keys:worker_mobility_percentages.keys{
			if selection < student_mobility_percentages[mode] + sum{
				return mode;
			}
			sum <- sum + student_mobility_percentages[mode];
		}
		return one_of(student_mobility_percentages.keys);
	}
}

species workplace{
	string id;
	string activity_code;
	string place_name;
	string str_nb_employees;
	int nb_employees;
}

species block{
	string id;
	//Population
	int nb_0to2;
	int nb_3to5;
	int nb_6to11;
	int nb_12to14;
	int nb_15to17;
	int nb_18to24;
	int nb_25to64;
	int nb_65_and_more;
	int nb_people;
}
experiment execute type:batch until:cycle=1{
	
}
