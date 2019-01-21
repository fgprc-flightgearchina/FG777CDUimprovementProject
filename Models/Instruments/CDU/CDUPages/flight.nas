

var LegsModel = 
{
    _wpIndexFromModel: func(index) { index + flightplan().current; },
    
    _wpFromModel: func(index) { flightplan().getWP(me._wpIndexFromModel(index)); },
    
    _ndPlanModeActive: func { getprop('instrumentation/efis/mfd/mode-num') == 3; },
    
    new: func()
    {
      m = {parents: [LegsModel, CDU.AbstractModel.new()]};
      
      
        
      return m;
    },
    
    firstLineForLegs: func 0,
    countForLegs: func { 
        var fp = flightplan();
        return fp.getPlanSize() - fp.current;
    },
    firstLineForSpeedAlt: func 0,
    countForSpeedAlt: func { 
        var fp = flightplan();
        return fp.getPlanSize() - fp.current;
    },
    
    titleForLegs: func(index)
    {
        var wp = me._wpFromModel(index);
        if (wp==nil) return nil;
        
        if (wp.leg_distance < 10)
            return sprintf('~%3dg     %3dNM', wp.leg_bearing, wp.leg_distance);
        sprintf('~%3dg    %4dNM', wp.leg_bearing, int(wp.leg_distance));
    },
        
    dataForLegs: func(index)
    {
        var wp = me._wpFromModel(index);
        if (me._ndPlanModeActive() and (index == getprop('instrumentation/efis/inputs/plan-wpt-index'))) {
            return wp.wp_name ~ '   <CTR>';
        }
        
        return wp.wp_name;
    },
    
    dataForSpeedAlt: func(index)
    {
        var wp = me._wpFromModel(index);
        return CDU.formatWayptSpeedAltitude(wp);
    },
    
    selectLegs: func(index) 
    {   
        return 1;
    },
    
};

var legsPage = CDU.MultiPage.new(cdu:cdu, title:"      RTE 1 LEGS", model:LegsModel.new(), dynamicActions:1);

legsPage.addAction(CDU.Action.new('ACTIVATE', 'R6', 
	func {
		cdu.setExecCallback(activateRoute);
	},
	func {
		var inactive = (getprop('autopilot/route-manager/active') == 0);
		var fp = flightplan();
		return inactive and (fp.departure != nil) and (fp.destination != nil);
	}
));
		  
legsPage.addAction(CDU.Action.new('RTE DATA', 'R6', 
    func { cdu.displayPageByTag("route-data"); }, 
    func { 
		var act = (getprop('autopilot/route-manager/active') != 0);
		return act and (getprop('instrumentation/efis/mfd/mode-num') != 3);
	}
));

# note spaces in title to ensure we over-write 'RTE DATA' when updating
legsPage.addAction(CDU.Action.new('    STEP', 'R6', func {
    var cur = getprop('instrumentation/efis/inputs/plan-wpt-index');
    if ((cur += 1) >= flightplan().getPlanSize()) 
        cur = flightplan.current;
    
    setprop('instrumentation/efis/inputs/plan-wpt-index', cur);
}, 
func {
    getprop('instrumentation/efis/mfd/mode-num') == 3;
}
));
    
legsPage.addField(CDU.ScrolledField.new(tag:'Legs', selectable:1));
legsPage.addField(CDU.ScrolledField.new(tag:'SpeedAlt', alignRight:1));

cdu.addPage(legsPage, "legs");

#############

var RteDataModel = 
{
    _wpIndexFromModel: func(index) { index + flightplan().current; },
    
    _wpFromModel: func(index) { flightplan().getWP(me._wpIndexFromModel(index)); },
    
    _ndPlanModeActive: func { getprop('instrumentation/efis/mfd/mode-num') == 3; },
    
    new: func()
    {
      m = {parents: [RteDataModel, CDU.AbstractModel.new()]};
      
      return m;
    },
    
    firstLineForRteData: func 0,
    countForRteData: func { 
        var fp = flightplan();
        return return fp.getPlanSize() - fp.current;
    },
    
    titleForRteData: func(index)
    {
		
    },
        
    dataForRteData: func(index)
    {
        var wp = me._wpFromModel(index);
		if (index < 2) {
			var eta = getprop("autopilot/route-manager/wp["~index~"]/eta-seconds") or -1;
			if (eta > 0) {
				eta = getprop("/sim/time/utc/day-seconds") + eta;
				var h = math.floor(eta/3600);
				eta=eta-3600*h;
				var m = math.floor(eta/60);
				if (h>24) h=h-24;
				return sprintf("~%02d%02dZ",h,m)~'! '~wp.wp_name;
			}
		}
        return '      '~wp.wp_name;
    },
    
    dataForSpeedAlt: func(index)
    {
        var wp = me._wpFromModel(index);
        return CDU.formatWayptSpeedAltitude(wp);
    },
    
    selectRteData: func(index) 
    {   
        return 1;
    },
    
};

var rteDataPage = CDU.MultiPage.new(cdu:cdu, title:"      RTE 1 DATA", model:RteDataModel.new(), dynamicActions:1);

rteDataPage.addAction(CDU.Action.new('LEGS', 'R6', 
    func { cdu.displayPageByTag("legs"); }
));

rteDataPage.addField(CDU.ScrolledField.new(tag:'RteData', selectable:1, dynamic:1));
rteDataPage.addField(CDU.Field.new(pos:'L1', title:'~ ETA    WPT   FUEL  WIND', tag:''));

cdu.addPage(rteDataPage, "route-data");

#############

var ClimbModel = 
{
    new: func()
    {
      m = {parents: [ClimbModel, CDU.AbstractModel.new()]};
      return m;
    },
    
    _nextAltRestrictionWP:  func
    {
        var fp = flightplan();
            
        # FIXME - stop after hitting cruise altitude wp, so we don't
        # report descent altitude restrictions
        
        for (var index = fp.current; index < fp.getPlanSize(); index += 1) {
            var wp = fp.getWP(index);
            if (wp.alt_cstr != nil) return wp;
        }
        
        return nil;
    },
    
    dataForCruiseAltitude: func { 
        CDU.formatAltitude(getprop('autopilot/route-manager/cruise/altitude-ft'));
    },
    
    editCruiseAltitude: func(scratch) {
        return 0; # FIXME
    },
    
    titleForClimbThrust: func {
        var sel = getprop('instrumentation/fmc/inputs/climb-derate-index');
        if (sel == 0) return 'CLB N1';
        return sprintf('CLB-%d N1', sel);
    },
    
    dataForClimbThrust: func {
        var n1 = getprop('instrumentation/fmc/climb/climb-thrust-n1');
        return sprintf('%4.1f/ %4.1f%%', n1 * 100, n1 * 100);
    },
    
    titleForNextRestrictionAltitude: func {
        var wp = me._nextAltRestrictionWP();
        if (wp == nil) return nil;
        return '~AT ' ~ wp.wp_name;
    },
    
    dataForNextRestrictionAltitude: func {
        return formatAltRestriction(me._nextAltRestrictionWP());
    },
    
    dataForTargetSpeed: func {
        sprintf('%3d/.%03d', getprop('instrumentation/fmc/climb/target-speed-kt'),
            getprop('instrumentation/fmc/climb/target-speed-mach') * 1000);
    },
    
    dataForSpeedRestriction: func {
        var restrictedSpeed = getprop('/instrumentation/fmc/active-speed-restrict-kt');
        if (restrictedSpeed < 0) return nil; # no restriction
        
        return sprintf('%3d/%s', restrictedSpeed, getprop('instrumentation/fmc/speed-restrict-reason'));
    },
    
    titleForTimeDistanceToNextRestriction: func {
        var wp = me._nextAltRestrictionWP();
        if (wp == nil) return nil;
        return '~TO ' ~ wp.wp_name;
    },
    
    dataForTimeDistanceToNextRestriction: func {
        var wp = me._nextAltRestrictionWP();
        if (wp == nil) return nil;
        
        var dist = 0.0;
        var wpArrivalTime = 0.0;
        
        return sprintf('%6.1fz/%3dnm', wpArrivalTime, dist);
    },
    
    dataForNextRestrictionError: func {
        var wp = me._nextAltRestrictionWP();
        if (wp == nil) return nil;
        return '150lo'; # TODO
    },
};

var climb = CDU.Page.new(owner:cdu, title:"             CLB", model:ClimbModel.new());

climb.addAction(CDU.Action.new('ECON', 'L5', func {} ));
#climb.addAction(CDU.Action.new('MAX RATE', 'L5', func {} ));
climb.addAction(CDU.Action.new('ENG OUT', 'R5', func {cdu.displayPageByTag("engine-out");} ));
#climb.addAction(CDU.Action.new('RTA', 'R6', func {cdu.displayPageByTag("rta");} ));
  
climb.addField(CDU.Field.new(pos:'L1', title:'~CRZ ALT', tag:'CruiseAltitude'));
#climb.addField(CDU.Field.new(pos:'L2', title:'~SEL SPD', tag:'TargetSpeed'));
climb.addField(CDU.Field.new(pos:'L4', title:'~SPD RESTR', tag:'SpeedRestriction', dynamic:1));

climb.addField(CDU.Field.new(pos:'R1', tag:'NextRestrictionAltitude'));
#climb.addField(CDU.Field.new(pos:'R2', tag:'TimeDistanceToNextRestriction', dynamic:1));
climb.addField(CDU.Field.new(pos:'R3', title:'~ERROR',tag:'NextRestrictionError', dynamic:1));
climb.addField(CDU.StaticField.new(pos:'R4', title:'~MAX ANGLE'));

#climb.addField(CDU.Field.new(pos:'R4', tag:'ClimbThrust'));

#############

var CruiseModel = 
{
    new: func()
    {
      m = {parents: [CruiseModel, CDU.AbstractModel.new()]};
      return m;
    },

    dataForCruiseAltitude: func { 
        CDU.formatAltitude(getprop('autopilot/route-manager/cruise/altitude-ft'));
    },
    
    dataForOptMaxAltitude: func {
        var optAlt = getprop('instrumentation/fmc/cruise/optimum-altitude-ft');
        var maxAlt = getprop('instrumentation/fmc/cruise/max-altitude-ft');
        if ((optAlt < 0) or (maxAlt < 0)) return nil;
        
        CDU.formatAltitude(optAlt) ~ '/' ~ CDU.formatAltitude(maxAlt)
    },
    
    editCruiseAltitude: func(scratch) {
        return 0; # FIXME
    },
    
    dataForTargetSpeed: func {
        var useMach = 0;
        if (useMach) {
            return sprintf('%03d',getprop('instrumentation/fmc/cruise/target-speed-mach') * 1000);
        } else {
            return sprintf('%3d', getprop('instrumentation/fmc/cruise/target-speed-kt'));
        }
    },
    
    dataForTimeDistanceToTopDescent: func
    {
        var dist = 0.0;
        var tdArrivalTime = 0.0;
        
        return sprintf('%6.1f~Z~/%3d~NM', tdArrivalTime, dist);
    },
    
    dataForStep: func() {
        var alt = getprop('instrumentation/fmc/cruise/step-altitude-ft');
        if (alt < 1) return CDU.EMPTY_FIELD5;
        CDU.formatAltitude(alt);
    },
    
    editStep: func(scratch) {
        var stepAlt = CDU.parseAltitude(scratch);
        if (stepAlt > 0) {
            setprop('instrumentation/fmc/input/step-altitude-ft', stepAlt);
            return 1;
        }
        
        return 0;
    },
    
    dataForWind: func {
        var windHdg = getprop('environment/wind-from-heading-deg');
        var windSpeed = getprop('environment/wind-speed-kt');
        return CDU.formatBearingSpeed(windHdg, windSpeed);
    },
    
    dataForTurbulenceN1: func {
        var n1 = 0.90;
        return sprintf('%4.1f/ %4.1f%%', n1 * 100, n1 * 100);
    },
    
    titleForFuelAtDestination: func {
        return '~FUEL AT ' ~ flightplan().destination.id;
    },
    
    dataForFuelAtDestination: func {
        
    },
};

var cruise = CDU.Page.new(owner:cdu, title:"             CRZ", model:CruiseModel.new());

cruise.addAction(CDU.Action.new('LRC', 'L6', func {} ));  
cruise.addAction(CDU.Action.new('ENG OUT', 'R5', func {cdu.displayPageByTag("engine-out");} ));    
cruise.addAction(CDU.Action.new('RTA', 'R6', func {cdu.displayPageByTag("rta");} ));
  
cruise.addField(CDU.Field.new(pos:'L1', title:'~CRZ ALT', tag:'CruiseAltitude'));

cruise.addField(CDU.Field.new(pos:'L2', title:'~ECON SPD', tag:'TargetSpeed'));
cruise.addField(CDU.Field.new(pos:'L3', title:'~N1', tag:'TurbulenceN1'));

cruise.addField(CDU.Field.new(pos:'R1', title:'~STEP', tag:'Step'));
cruise.addField(CDU.Field.new(pos:'R2', title:'~TO T/D', tag:'TimeDistanceToTopDescent'));
cruise.addField(CDU.Field.new(pos:'R3', tag:'FuelAtDestination'));
cruise.addField(CDU.Field.new(pos:'R4', title:'~  OPT    MAX', tag:'OptMaxAltitude'));

cruise.fixedSeparator = [4, 4];

#############

var DescentModel = 
{
    new: func()
    {
      m = {parents: [DescentModel, CDU.AbstractModel.new()]};
      return m;
    },
};

var descent = CDU.Page.new(owner:cdu, title:"             DES", model:DescentModel.new());

descent.addAction(CDU.Action.new('FORECAST', 'R5', func {} ));
descent.addAction(CDU.Action.new('OFFPATH DES', 'L6', func {} ));
descent.addAction(CDU.Action.new('DES DIR', 'R6', func {} ));

descent.fixedSeparator = [4, 4];

CDU.linkPages([climb, cruise, descent]);
cdu.addPage(climb, "climb");
cdu.addPage(cruise, "cruise");
cdu.addPage(descent, "descent");

#############

var ApproachModel = 
{
    new: func()
    {
      m = {parents: [ApproachModel, CDU.AbstractModel.new()]};
      return m;
    },
	
    dataForVref25: func { 
        var vref = getprop('instrumentation/fmc/speeds/vref25-kt');
		if (vref != 0) return sprintf('25g   %3d', vref)~'~KT';
    },
	
    dataForVref30: func { 
        var vref = getprop('instrumentation/fmc/speeds/vref30-kt');
		if (vref != 0) return sprintf('30g   %3d', vref)~'~KT';
    },
	
    titleForRwyLength: func { 
		if (flightplan().departure == nil) return 0;
		sprintf('~%s%s',flightplan().departure.id,flightplan().departure_runway.id);
	},
    dataForRwyLength: func {
		if (flightplan().departure == nil) return 0;
        sprintf('%5d~FT!%4d~M', flightplan().departure_runway.length * M2FT, flightplan().departure_runway.length);
    },
	
    dataForFlaps: func {
        var f = getprop('instrumentation/fmc/landing/landing-flaps');
		var s = getprop('instrumentation/fmc/landing/vapp-kt') or '---';
        if (f != 25 and f != 30) return '--/'~s;
        return sprintf('%2d', f)~'/'~s;
    },
    
    editFlaps: func(scratch) {
        var fields = CDU.parseDualFieldInput(scratch);
        debug.dump('fields:', scratch, fields);
		if (size(fields[0]) == 3) {
			fields[1] = fields[0];
			fields[0] = nil;
		}
        
        if (fields[0] != nil) {
            var f = num(fields[0]);
			if ((f != 25) and (f != 30)) return 0;
			setprop('instrumentation/fmc/landing/landing-flaps', f);
			Boeing747.vspeeds();
        }
        
        if (fields[1] != nil) {
            var n = fields[1];
            setprop('instrumentation/fmc/landing/vapp-kt', n);
			Boeing747.vspeeds();
        }
		
        return 1;
    },
};

var approach = CDU.Page.new(owner:cdu, title:"      APPROACH REF", model:ApproachModel.new());

approach.addField(CDU.StaticField.new(pos:'L1', title:'~GROSS WT'));
#approach.addField(CDU.StaticField.new('L1+12', '~FLAPS', ' 25g'));
#approach.addField(CDU.StaticField.new('L2+12', '', ' 30g'));
approach.addField(CDU.Field.new(pos:'R1', title:'~FLAPS   VREF', tag:'Vref25'));
approach.addField(CDU.Field.new(pos:'R2', tag:'Vref30'));
approach.addField(CDU.Field.new(pos:'R4', title:'~FLAP/SPEED', tag:'Flaps'));
approach.addField(CDU.Field.new(pos:'L4', tag:'RwyLength'));
approach.addAction(CDU.Action.new('INDEX', 'L6', func {cdu.displayPageByTag("index");} ));
approach.addAction(CDU.Action.new('THRUST LIM', 'R6', func {cdu.displayPageByTag("thrust-lim");} ));

cdu.addPage(approach, "approach");