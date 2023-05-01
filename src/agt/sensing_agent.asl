// sensing agent


/* Initial beliefs and rules */
role_goal(R, G) :-
	role_mission(R, _, M) & mission_goal(M, G).

can_achieve (G) :-
	.relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].

i_have_plans_for(R) :-
       not (role_goal(R, G) & not can_achieve(G)).

role_available(R) :- 
		role_cardinality(R, Min, Max) & 
		.count(play(_,R,_),NumberOfAgents) & 
		Max > NumberOfAgents.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

/*
	found the bug, I wrote "lookUpArtifact" instead of "lookupArtifact" 🙈
*/
+new_organisation(Workspace, Artifact) : true <-
	joinWorkspace(Workspace, WspID1);
	lookupArtifact(Artifact, OrgArtId);
	focus(OrgArtId);
	.print("focused on Organisation").

+new_group(GrpName) : true <-
	lookupArtifact(GrpName, GrpArtId);
	focus(GrpArtId);
	.print("focused on Group: ", GrpName);
	!check_for_open_roles(GrpArtId).

+!check_for_open_roles(GrpArtId) : role(R,G) & role_available(R) & i_have_plans_for(R) <-
  .print("Found open role: ", R);
  adoptRole(R).

+!check_for_open_roles(GrpArtId) : role(R,G) & not role_available(R) & i_have_plans_for(R) <-
  .print("Found open role, but it is not available: ", R).

+!check_for_open_roles(GrpArtId) : role(R,G) & role_available(R) & not i_have_plans_for(R) <-
  .print("Found open role, but I do not have plans for it: ", R).

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }