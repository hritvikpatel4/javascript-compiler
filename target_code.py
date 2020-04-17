def for_func(i):
    global x,start,end
    j=0
    for j in range(quads.index(i),len(quads)-1):
        if(quads[j][5]!=quads[j+1][5]):
            break
    print('B'+mappings[opp_mappings[i[1]]]+'Z '+reg+', '+quads[j+1][0])

    start=x+1
    while(quads[x][4]!=''):
        x+=1
    end=x


def tern_func(i):
    global flag,flag1
    j=quads.index(i)
    while(quads[j][4]!=''):
        j+=1
    print('B'+mappings[opp_mappings[i[1]]]+'Z '+reg+', '+quads[j+1][0])
    flag1=quads[j+1][0]

    j=0
    for j in range(quads.index(i),len(quads)-1):
        if(quads[j][5]!=quads[j+1][5]):
            break
    flag=quads[j+1][0]


def assign_expr(i):
    global reg
    global d
    res=''

    if(i[3].isnumeric()):
        res="#"+i[3]+", "
    elif(len(i[3])==2 and i[3].startswith('t')):
        if(i[3] in d):
            res=d[i[3]]+", "
        else:
            reg="r"+str(int(reg.split('r')[1])+1)
            res=reg+", "
            d[i[3]]=reg
    else:
        if(i[3] not in loaded):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("LD "+reg+", "+i[3])
            res=reg+", "
            loaded[i[3]]=reg
        else:
            res=loaded[i[3]]+", "


    if(i[4].isnumeric()):
        res=res+"#"+i[4]
    elif(len(i[4])==2 and i[4].startswith('t')):
        if(i[4] in d):
            res=res+d[i[4]]
        else:
            reg="r"+str(int(reg.split('r')[1])+1)
            res=res+reg
            d[i[4]]=reg
    else:
        if(i[4] not in loaded):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("LD "+reg+", "+i[4])
            res=res+reg
            loaded[i[4]]=reg
        else:
            res=res+loaded[i[4]]
    

    if(len(i[2])==2 and i[2].startswith('t')):
        if(i[2] in d):
            res=mappings[i[1]]+" "+d[i[2]]+", "+res
        else:
            reg="r"+str(int(reg.split('r')[1])+1)
            res=mappings[i[1]]+" "+reg+", "+res
            d[i[2]]=reg


    print(res)


def assign(i):
    global reg
    global d
    res=''

    if(len(i[3])==2 and i[3].startswith('t')):
        if(i[3] in d):
            res=d[i[3]]
        else:
            reg="r"+str(int(reg.split('r')[1])+1)
            res=reg
            d[i[3]]=reg

        if(i[2]=='temp'):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("MOV "+reg+", "+res)
            reg="r"+str(int(reg.split('r')[1])-1)
        else:
            if(i[2] not in to_store and i[2] not in loaded):
                loaded[i[2]]= reg
                to_store[i[2]]=reg
            elif(i[2] in loaded):
                to_store[i[2]]=loaded[i[2]]
                print("MOV "+to_store[i[2]]+", "+res)
            else:
                print("MOV "+to_store[i[2]]+", "+res)

    elif(i[3].isnumeric()):
        print('\n'+i[0])

        if(i[2]=='temp'):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("MOV "+reg+", #"+i[3])
            reg="r"+str(int(reg.split('r')[1])-1)
        else:
            if(i[2] not in to_store and i[2] not in loaded):
                reg="r"+str(int(reg.split('r')[1])+1)
                print("MOV "+reg+", #"+i[3])
                to_store[i[2]]=reg
                loaded[i[2]]= reg
            elif(i[2] in loaded):
                to_store[i[2]]=loaded[i[2]]
                print("MOV "+to_store[i[2]]+", #"+i[3])  
            else:
                print("MOV "+to_store[i[2]]+", #"+i[3])
            

    else:
        if(i[3] not in loaded):
            print('\n'+i[0])
            reg="r"+str(int(reg.split('r')[1])+1)
            print("LD "+reg+", "+i[3])
            res=reg
        else:
            print('\n'+i[0])
            res=loaded[i[3]]

        
        if(i[2]=='temp'):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("MOV "+reg+", "+res)
            reg="r"+str(int(reg.split('r')[1])-1)
        else:
            if(i[2] not in to_store and i[2] not in loaded):
                loaded[i[2]]= res
                to_store[i[2]]=res
            elif(i[2] in loaded):
                to_store[i[2]]=loaded[i[2]]
                print("MOV "+to_store[i[2]]+", "+res)  
            else:
                print("MOV "+to_store[i[2]]+", "+res)    

    pos_mappings[i[2]]=i[0]
    
    

def cond(i):

    global reg,d
    res=''

    if(len(i[3])==2 and i[3].startswith('t')):
        if(i[3] in d):
            res=d[i[3]]
        else:
            reg="r"+str(int(reg.split('r')[1])+1)
            res=reg
            d[i[3]]=reg
    elif(i[3].isnumeric()):
        reg="r"+str(int(reg.split('r')[1])+1)
        print('MOV '+reg+", #"+i[3])
        res=reg
    else:
        if(i[3] not in loaded):
            reg="r"+str(int(reg.split('r')[1])+1)
            print("LD "+reg+", "+i[3])
            res=reg
            loaded[i[3]]=reg
        else:
            res=loaded[i[3]]



    if(i[4].isnumeric()):
        if(i[4]=='0'):
            if(i[5].startswith('for')):
                for_func(i)
            elif(i[5].startswith('tern')):
                tern_func(i)
            else:
                print('B'+mappings[i[1]]+'Z '+res+', '+i[5])

        else:
            if(reg in to_store.values()):
                reg="r"+str(int(reg.split('r')[1])+1)
            res=reg+', '+res
            print('SUB '+res+', '+'#'+i[4])

            if(i[5].startswith('for')):
                for_func(i)
            elif(i[5].startswith('tern')):
                tern_func(i)
            else:
                print('B'+mappings[i[1]]+'Z '+reg+', '+i[5])

            reg="r"+str(int(reg.split('r')[1])-1)
    

    else:
        if(len(i[4])==2 and i[4].startswith('t')):
            if(i[4] in d):
                res=res+', '+d[i[4]]
            else:
                reg="r"+str(int(reg.split('r')[1])+1)
                res=res+', '+reg
                d[i[4]]=reg
        else:
            if(i[4] not in loaded):
                reg="r"+str(int(reg.split('r')[1])+1)
                print("LD "+reg+", "+i[4])
                res=res+', '+reg
                loaded[i[4]]=reg
            else:
                res=res+', '+loaded[i[4]]

        reg="r"+str(int(reg.split('r')[1])+1)
        print('SUB '+reg+', '+res)

        if(i[5].startswith('for')):
            for_func(i)
        elif(i[5].startswith('tern')):
            tern_func(i)
        else:
            print('B'+mappings[i[1]]+'Z '+reg+', '+i[5])

        reg="r"+str(int(reg.split('r')[1])-1)


        

f= open("/Users/shreyasbs/Desktop/Academic/Sem6/CD/Project/target/quad.txt","r")

quads=[]
d={}
to_store={}
loaded={}
pos_mappings={}

flag=-1
flag1=-1
start=0
end=0

mappings={'+':'ADD','-':'SUB','*':'MUL','/':'DIV','>':'GT','<':'LT','>=':'GE','<=':'LE','==':'EQ','!=':'NE'}
opp_mappings={'>':'<=','<':'>=','<=':'>','>=':'<','==':'!='}

current_block=''

reg="r-1"

for i in f:
    if(i!='\n'):
        i=i.rstrip('\n')
        j=i.split(";")
        quads.append(j)

print(quads)

x=0
while(x<len(quads)):
    if(current_block!=quads[x][5]):
        if(current_block.startswith('for')):
            for y in range(start,end+1):
                if(quads[y][1]=='=' and quads[y][4]=='' and quads[y][2]!=''):
                    assign(quads[y])
                
                if(quads[y][1]!='' and quads[y][1]!='=' and quads[y][2]!=''):
                    print('\n'+quads[y][0])
                    assign_expr(quads[y])

            print('B '+current_block)

        print('\n'+quads[x][5]+':')
        print('------------')
        current_block=quads[x][5]
    
    if(quads[x][0]==flag1):
        print('B '+flag)

    if(quads[x][1]=='=' and quads[x][4]=='' and quads[x][2]!=''):
        assign(quads[x])
    
    if(quads[x][1]!='' and quads[x][1]!='=' and quads[x][2]!=''):
        print('\n'+quads[x][0])
        assign_expr(quads[x])

    if(quads[x][2]=='' and quads[x][3]!=''):
        print('\n'+quads[x][0])
        cond(quads[x])
    
    x+=1

for i in to_store:
    print(pos_mappings[i])
    print("ST "+to_store[i]+", "+i+'\n')










'''
TODO:

LOOK AT INCREMENT STATEMENT IN for
REGISTERS IN TERNARY
'''