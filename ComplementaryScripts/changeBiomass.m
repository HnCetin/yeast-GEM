%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% model = changeBiomass(model,P,GAM,NGAM)
%
% Benjam�n J. S�nchez. Last edited: 2017-10-31
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function model = changeBiomass(model,P,GAM,NGAM)

%Recalculate GAM based on original GAM:
Pbase    = 0.4668;         %Value from original biomass comp. (F�rster data @ 0.1 1/h)
Cbase    = 0.4514;         %Value from original biomass comp. (F�rster data @ 0.1 1/h)
Pfactor  = P/Pbase;
Cfactor  = (Cbase+Pbase-P)/Cbase;    %Assumption: change in protein is balanced with a change in carbohydrate
full_GAM = GAM + 16.965*Pfactor + 5.210*Cfactor;

%Get current contents and calculate conversion factors for proteins and carbs:
[Pbase,Cbase] = calculateContent(model);
Pfactor = P/Pbase;
Cfactor = (Cbase+Pbase-P)/Cbase;    %Assumption: change in protein is balanced with a change in carbohydrate

%Change biomass composition:
bio_pos = strcmp(model.rxns,'r_4041');
for i = 1:length(model.mets)
    S_ix = model.S(i,bio_pos);
    if S_ix ~= 0        
        name  = model.metNames{i};
        isaa  = ~isempty(strfind(name,'tRNA'));
        isATP = strcmpi(name,'ATP [cytoplasm]');
        isADP = strcmpi(name,'ADP [cytoplasm]');
        isH2O = strcmpi(name,'H2O [cytoplasm]');
        isH   = strcmpi(name,'H+ [cytoplasm]');
        isP   = strcmpi(name,'phosphate [cytoplasm]');
        isCH  = sum(strcmpi({'(1->3)-beta-D-glucan [cell envelope]', ...
                             '(1->6)-beta-D-glucan [cell envelope]', ...
                             'chitin [cytoplasm]','glycogen [cytoplasm]', ...
                             'mannan [cytoplasm]','trehalose [cytoplasm]'},name)) == 1;
        
        %Variable ATP growth related maintenance (GAM):
        if isATP || isADP || isH2O || isH || isP
            S_ix = sign(S_ix)*full_GAM;
        
        %Variable aa content in biomass eq:
        elseif isaa
            S_ix = S_ix*Pfactor;
            
        %Variable carb content in biomass eq:
        elseif isCH
            S_ix = S_ix*Cfactor;
        end
        
        model.S(i,bio_pos) = S_ix;
    end
end

%Add NGAM reaction:
%                ATP    +    H2O    ->  ADP     +   H+      +  PO4
mets      = {'s_0434[c]','s_0803[c]','s_0394[c]','s_0794[c]','s_1322[c]'};
coefs     = [-1,-1,1,1,1];
[model,~] = addReaction(model,{'NGAM','non-growth associated maintenance reaction'}, ...
                        mets,coefs,false,NGAM,NGAM);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%