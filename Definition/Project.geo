// Gmsh project created on Mon Feb 24 15:19:05 2020

SetFactory("OpenCASCADE"); //I used predefined functions :)

//Including data
Include "Project_data.geo"; 

//Deleting duplicatas
Coherence;

//********************* Geometrical calculations *********************//

// Dimension of the new conductor
alpha = 2*Pi/Num_litz; 
If (Num_litz == 1)
	Rayon  = 0;
Else
	If (Flag_Insulation )
		Rayon  = (2*(Rc+d_cond))/(Sqrt((1-Cos(alpha))*(1-Cos(alpha))+(Sin(alpha))*(Sin(alpha))))+Insulation; // Imaginary circle radius
	Else
		Rayon  = (2*(Rc+d_cond))/(Sqrt((1-Cos(alpha))*(1-Cos(alpha))+(Sin(alpha))*(Sin(alpha))));	     // Imaginary circle radius	
	EndIf
EndIf

// Domain size: param is used to define the coordinates of the rectangular air box
If (Flag_Insulation)
	param = Rayon + Rc + Insulation + R_airbox; 
Else
	param = Rayon + Rc + R_airbox; 
EndIf

// Mesh size
lc_Conductor  = Rc / 50     ;
lc_Insulation = lc_Conductor;
lc_Air        = (2*param)/50;

//********************* Creation of the geometry *********************//
//Non-insulated conductors
cp = newp ;
Point(cp)   = {Rayon     , 0    , 0 ,lc_Conductor} ;
Point(cp+1) = {Rayon + Rc, 0    , 0 ,lc_Conductor} ;
Point(cp+2) = {Rayon     , Rc   , 0 ,lc_Conductor} ;
Point(cp+3) = {Rayon - Rc, 0    , 0 ,lc_Conductor} ;
Point(cp+4) = {Rayon     ,-Rc   , 0 ,lc_Conductor} ;

cl  = newl ;
Circle(cl)   = {cp+1, cp, cp+2} ;
Circle(cl+1) = {cp+2, cp, cp+3} ;
Circle(cl+2) = {cp+3, cp, cp+4} ;
Circle(cl+3) = {cp+4, cp, cp+1} ;

For j In {0:3}
	skin_conductor() += cl+j;
EndFor

cll = newll; 
Line Loop(cll) = {skin_conductor()} ;

cs  = news;
Plane Surface(cs) = {cll};
b_c() += {skin_conductor()} ;
Surf_c() += cs;

//Air box
cp = newp;
 	Point(cp)   = { param, param, 0 , lc_Air} ;
	Point(cp+1) = {-param, param, 0 , lc_Air} ;
	Point(cp+2) = {-param,-param, 0 , lc_Air} ;
	Point(cp+3) = { param,-param, 0 , lc_Air} ;

cl = newl;
	Line(cl)   = {cp  , cp+1} ;
	Line(cl+1) = {cp+1, cp+2} ;
	Line(cl+2) = {cp+2, cp+3} ;
	Line(cl+3) = {cp+3, cp  } ;

For j In {0:3}
	skin_airbox() += cl+j;
EndFor

abll = newll; 
Line Loop(abll) = {skin_airbox()};

//Defining the Surface of The AirBox:
c_ab  = news; Plane Surface(c_ab) = {abll};

//Circular arrangement of the naked conductors:
For i In {1:Num_litz-1}
	out_c[]  = Rotate{{0,0,1},{0,0,0},alpha}{Duplicata{Surface{cs};}};
 	cs       = out_c[0] ;
 	Surf_c()+= out_c[0] ;          //Surface copper without insulation
 	b_c()   += Boundary{Surface{cs};}  ;
EndFor

//Insulation
If (Flag_Insulation)
	cp = newp;
	Point(cp)   = {Rayon                     , 0                 , 0 ,lc_Conductor} ;
	Point(cp+1) = {Rayon + Rc + Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+2) = {Rayon                     , Rc + Insulation, 0 ,lc_Insulation} ;
	Point(cp+3) = {Rayon - Rc - Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+4) = {Rayon                     ,-Rc - Insulation, 0 ,lc_Insulation} ;

	cl = newl;
	Circle(cl)   = {cp+1, cp, cp+2} ;
	Circle(cl+1) = {cp+2, cp, cp+3} ;
	Circle(cl+2) = {cp+3, cp, cp+4} ;
	Circle(cl+3) = {cp+4, cp, cp+1} ;

	For j In {0:3}
		skin_Insulation() += cl+j; 
	EndFor

	ill = newll;         //Insulation Line loop
	Line Loop(ill)    = {skin_Insulation()} ;
	b_i() += {skin_Insulation};
	c_i    = news;

	Plane Surface(c_i) = {ill};
	Surf_c_w_i() += {c_i}     ; 

// Circular Arrangement of the insulated conductors:
	For i In {1:Num_litz-1}
		out_i[] = Rotate{{0,0,1},{0,0,0},alpha}{Duplicata{Surface{c_i};}}; //c_i = conductor with insulation
 		c_i  = out_i[0]                  ;
		Surf_c_w_i() += out_i[0]         ;  		
	EndFor

	d() = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c_w_i(0):Surf_c_w_i(#Surf_c_w_i()-1)};};
	For i In {0:#Surf_c_w_i()-1}
		e() += BooleanDifference{Surface{Surf_c_w_i(i)};Delete;}{Surface{Surf_c(i)};Delete;};
	EndFor
 	x()  = Boundary{Surface{d(0)};}; //x() will be needed for the physicals
	x() -= Boundary{Surface{e(0):e(#e()-1)};};
Else 
	d()  = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c()};Delete;};
	x()  = Boundary{Surface{d(0)};};
	x() -= b_c();
EndIf

//********************* Definition of the physicals *********************//

Physical Surface("AirbBox with holes", SURF_AIRBOX) = {d(0)}         ;
Physical Line("Airbox Skin", SKIN_AIRBOX) ={x()}                     ;
Physical Line("Skin of conductors",SKIN_CONDUCTORS) = {b_c()}        ;
If (Flag_Insulation)
	Physical Surface("Surface of Insulations",SURF_INSULATIONS)={e()};
EndIf
