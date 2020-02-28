Include "Project_data.geo";
Group {
  Skin_Airbox = Region[500000]; 
  Surf_Airbox = Region[600000];

  Skin_conductors = Region[700000];

  Vol_Ele = Region[ {Surf_Airbox} ];
  Sur_Neu_Ele = Region[ {} ];

  If (Flag_Insulation)
    Surf_Insulations = Region[900000];
    Vol_Ele += Region[{Surf_Insulations}];
  EndIf
}

Function {
  epsilon[Surf_Airbox]        = 1. * eps0;
  If (Flag_Insulation )
	epsr = Ins_epsr;
    epsilon[Surf_Insulations] = Ins_epsr * eps0;  
  EndIf
}

Constraint {
  { Name Dirichlet_Ele; Type Assign;
    Case {
      { Region Skin_Airbox    ; Value 0.     ; }
      { Region Skin_conductors; Value Voltage; }
    }
  }
}

Group{
  Dom_Hgrad_v_Ele =  Region[ {Vol_Ele, Sur_Neu_Ele} ];
}

FunctionSpace {
  { Name Hgrad_v_Ele; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef vn; Function BF_Node;
        Support Dom_Hgrad_v_Ele; Entity NodesOf[ All ]; }
    }
    Constraint {
      { NameOfCoef vn; EntityType NodesOf; NameOfConstraint Dirichlet_Ele; }
    }
  }
}

Include "../Libraries/Library.pro"; 

Formulation {
  { Name Electrostatics_v; Type FemEquation;
    Quantity {
      { Name v; Type Local; NameOfSpace Hgrad_v_Ele; }
    }
    Equation {
      Integral { [ epsilon[] * Dof{d v} , {d v} ];
	    In Vol_Ele; Jacobian Vol; Integration Int; }
    }
  }
}

Resolution {
  { Name EleSta_v;
    System {
      { Name Sys_Ele; NameOfFormulation Electrostatics_v; }
    }
    Operation {
      Generate[Sys_Ele]; Solve[Sys_Ele]; SaveSolution[Sys_Ele];
    }
  }
}

PostProcessing {
  { Name EleSta_v; NameOfFormulation Electrostatics_v;
    Quantity {
      { Name v; Value {
          Term { [ {v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
      { Name e; Value {
          Term { [ -{d v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
      { Name d; Value {
          Term { [ -epsilon[] * {d v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
    }
  }
}

PostOperation {
  { Name Map; NameOfPostProcessing EleSta_v;
     Operation {
       Print [ v, OnElementsOf Vol_Ele, File "Homework1_V.pos" ];
       Print [ e, OnElementsOf Vol_Ele, File "Homework1_E.pos" ];
     }
   }
  }


