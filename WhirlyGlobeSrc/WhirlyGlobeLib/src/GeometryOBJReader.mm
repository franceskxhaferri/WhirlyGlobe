/*
 *  GeometryOBJReader.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 11/25/14.
 *  Copyright 2012-2014 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <stdio.h>
#import "GeometryOBJReader.h"

namespace WhirlyKit
{
    
bool GeometryModelOBJ::parseMaterials(FILE *fp)
{
    bool success = true;
    Material *activeMtl = NULL;
    
    char line[2048];
    int lineNo = 0;
    
    while (fgets(line, 2047, fp))
    {
        lineNo++;
        int lineLen = strlen(line);
        
        // Empty line
        if (lineLen == 0 || line[0] == '\n')
            continue;
        // Comment
        if (line[0] == '#')
            continue;
        // Chop off a \r
        if (line[lineNo-1]  == '\r')
        {
            line[lineNo-1] = 0;
            lineNo--;
        }
        
        std::vector<char *> toks;
        // Parse the various tokens into an array
        char *tok = NULL;
        char *ptr = line;
        char *next = NULL;
        while ( (tok = strtok_r(ptr, " \t\n\r", &next)) )
        {
            toks.push_back(tok);
            ptr = next;
        }
        
        char *key = toks[0];
        
        if (!strcmp(key,"newmtl"))
        {
            if (toks.size() < 2)
            {
                success = false;
                break;
            }
            
            char *name = toks[1];
            materials.resize(materials.size()+1);
            Material &mat = materials[materials.size()-1];
            activeMtl = &materials.back();
            mat.name = name;
        } else if (!strcmp(key,"Ka"))
        {
            if (toks.size() < 4 || !activeMtl)
            {
                success = false;
                break;
            }
            
            for (unsigned int ii=0;ii<3;ii++)
                activeMtl->Ka[ii] = atof(toks[ii+1]);
        } else if (!strcmp(key,"Kd"))
        {
            if (toks.size() < 4 || !activeMtl)
            {
                success = false;
                break;
            }
            
            for (unsigned int ii=0;ii<3;ii++)
                activeMtl->Kd[ii] = atof(toks[ii+1]);
            
        } else if (!strcmp(key,"Ks"))
        {
            if (toks.size() < 4 || !activeMtl)
            {
                success = false;
                break;
            }
            
            for (unsigned int ii=0;ii<3;ii++)
                activeMtl->Ks[ii] = atof(toks[ii+1]);
        } else if (!strcmp(key,"d") || !strcmp(key,"Tr"))
        {
            if (toks.size() < 2 || !activeMtl)
            {
                success = false;
                break;
            }
            
            activeMtl->trans = atof(toks[1]);
        } else if (!strcmp(key,"illum"))
        {
            if (toks.size() < 2 || !activeMtl)
            {
                success = false;
                break;
            }
            
            activeMtl->illum = atof(toks[1]);
        } else if (!strcmp(key,"map_Ks"))
        {
            if (toks.size() < 2 || !activeMtl)
            {
                success = false;
                break;
            }
            
            activeMtl->tex_ambient = toks[1];
        } else if (!strcmp(key, "map_Kd"))
        {
            if (toks.size() < 2 || !activeMtl)
            {
                success = false;
                break;
            }
            
            activeMtl->tex_diffuse = toks[1];
        }
        // Note: Ignoring map_d, map_bump, map_Ks, map_Ns or any of the options
    }
    
    return success;
}

bool GeometryModelOBJ::parse(FILE *fp)
{
    bool success = true;
    Group *activeGroup = NULL;
    
    char line[2048],tmpTok[2048];
    int lineNo = 0;
    
    while (fgets(line, 2047, fp))
    {
        lineNo++;
        int lineLen = strlen(line);

        // Empty line
        if (lineLen == 0 || line[0] == '\n')
            continue;
        // Comment
        if (line[0] == '#')
            continue;
        // Chop off a \r
        if (line[lineNo-1]  == '\r')
        {
            line[lineNo-1] = 0;
            lineNo--;
        }
        
        std::vector<char *> toks;
        // Parse the various tokens into an array
        char *tok = NULL;
        char *ptr = line;
        char *next = NULL;
        while ( (tok = strtok_r(ptr, " \t\n\r", &next)) )
        {
            toks.push_back(tok);
            ptr = next;
        }
        
        char *key = toks[0];
        if (!strcmp(key,"mtllib"))
        {
            if (toks.size() < 2)
            {
                success = false;
                break;
            }
            
            // Note: Parse material file
            char *mtlFile = toks[1];
            
            // Load the model
            NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%s",mtlFile]];
            FILE *mtlFP = fopen([fullPath cStringUsingEncoding:NSASCIIStringEncoding],"r");
            if (!mtlFP)
            {
                success = false;
                break;
            }
            if (!parseMaterials(mtlFP))
            {
                success = false;
                break;
            }
            fclose(mtlFP);
        } else if (!strcmp(key,"usemtl"))
        {
            // Use a pre-defined material
            if (toks.size() < 1 || !activeGroup)
            {
                success = false;
                break;
            }
            
            // Look for the material
            std::string mtlName = toks[1];
            for (unsigned int ii=0;ii<materials.size();ii++)
            {
                if (mtlName == materials[ii].name)
                {
                    activeGroup->mtlID = ii;
                    break;
                }
            }
            
            if (activeGroup->mtlID < 0)
            {
                success = false;
                break;
            }
        } else if (!strcmp(key,"g"))
        {
            groups.resize(groups.size()+1);
            activeGroup = &groups.back();
            
            if (toks.size() > 1)
            {
                activeGroup->name = toks[1];
            } else {
                activeGroup->name = "";
            }
        } else if (!strcmp(key,"f"))
        {
            // Face
            if (toks.size() < 2)
            {
                success = false;
                break;
            }
            activeGroup->faces.resize(activeGroup->faces.size()+1);
            Face &face = activeGroup->faces.back();
            
            // We've either got numbers of collections of numbers separated by /
            for (unsigned int ii=1;ii<toks.size();ii++)
            {
                strcpy(tmpTok, toks[ii]);
                
                std::vector<char *> vertToks;
                char *vertTok = NULL;
                char *vertPtr = tmpTok;
                char *vertNext = NULL;
                while ( (vertTok = strtok_r(vertPtr, "/", &vertNext)) )
                {
                    vertToks.push_back(vertTok);
                    vertPtr = vertNext;
                }
                
                face.verts.resize(face.verts.size()+1);
                Vertex &vert = face.verts.back();
                if (vertToks.size() == 0)
                {
                    success = false;
                    break;
                }
                if (vertToks.size() >= 1)
                {
                    vert.vert = atoi(vertToks[0]);
                }
                if (vertToks.size() >= 2)
                {
                    vert.texCoord = atoi(vertToks[1]);
                }
                if (vertToks.size() >= 3)
                {
                    vert.norm = atoi(vertToks[2]);
                }
            }
        } else if (!strcmp(key,"v"))
        {
            // Regular vertex
            if (toks.size() < 4)
            {
                success = false;
                break;
            }
            
            verts.resize(verts.size()+1);
            Point3d &vert = verts.back();
            vert.x() = atof(toks[1]);
            vert.y() = atof(toks[2]);
            vert.z() = atof(toks[3]);
        } else if (!strcmp(key,"vn"))
        {
            // Normal
            if (toks.size() < 4)
            {
                success = false;
                break;
            }
            
            norms.resize(norms.size()+1);
            Point3d &norm = norms.back();
            norm.x() = atof(toks[1]);
            norm.y() = atof(toks[2]);
            norm.z() = atof(toks[3]);
        } else if (!strcmp(key,"vt"))
        {
            // Texture coordinate
            if (toks.size() < 3)
            {
                success = false;
                break;
            }
            
            texCoords.resize(texCoords.size()+1);
            Point2d &texCoord = texCoords.back();
            texCoord.x() = atof(toks[1]);
            texCoord.y() = atof(toks[2]);
        }
    }
    
    // Link up the materials
    for (unsigned int ii=0;ii<groups.size();ii++)
    {
        Group &group = groups[ii];
        group.mat = &materials[ii];
    }
    
    return success;
}

// Used to sort groups by texture name
class GroupBin
{
public:
    GroupBin(GeometryModelOBJ::Group *group) { groups.push_back(group); }
    bool operator < (const GroupBin &that) const
    {
        if (!groups[0]->mat || !that.groups[0]->mat)
            return groups[0]->mat < that.groups[0]->mat;
        return *(groups[0]->mat) < *(that.groups[0]->mat);
    }
    
    std::vector<GeometryModelOBJ::Group *> groups;
};
typedef std::set<GroupBin> GroupBinSet;
    
void GeometryModelOBJ::toRawGeometry(std::vector<GeometryRaw> &rawGeom)
{
    // Sort the groups by texture
    GroupBinSet groupBins;
    for (unsigned int ii=0;ii<groups.size();ii++)
    {
        GroupBin groupBin(&groups[ii]);
        const auto &it = groupBins.find(groupBin);
        if (it == groupBins.end())
            groupBins.insert(groupBin);
        else {
            groupBin.groups.insert(groupBin.groups.end(),it->groups.begin(), it->groups.end());
            groupBins.erase(it);
            groupBins.insert(groupBin);
        }
    }
}

}